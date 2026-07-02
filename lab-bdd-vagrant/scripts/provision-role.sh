#!/bin/bash
set +H
set -e

NODE_NAME=${NODE_NAME:-bdd-nodo00}
NODE_IP=${NODE_IP:-127.0.0.1}
NODE_ID=${NODE_ID:-0}
ROLE=${ROLE:-standalone}
MASTER_IP=${MASTER_IP:-}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-LabAdmin_2025!}
REPL_PASSWORD=${REPL_PASSWORD:-ReplUser_2025!}
MARKER="/var/lib/mysql/.provision-role-${ROLE}-complete"

if [ -f "$MARKER" ]; then
    echo "[$NODE_NAME] Rol $ROLE ya configurado, saltando."
    exit 0
fi

echo "=== [$NODE_NAME] Configurando rol: $ROLE (ID=$NODE_ID, IP=$NODE_IP) ==="

# ========== HOSTNAME & HOSTS ==========
echo "$NODE_NAME" > /etc/hostname
hostname "$NODE_NAME"

cat > /etc/hosts << HOSTS
127.0.0.1 localhost
::1 localhost ip6-localhost ip6-loopback
127.0.1.1 $NODE_NAME
192.168.56.101 bdd-nodo01
192.168.56.102 bdd-nodo02
192.168.56.103 bdd-nodo03
192.168.56.104 bdd-nodo04
192.168.56.105 bdd-nodo05
192.168.56.106 bdd-nodo06
HOSTS

# ========== CONFIG ESPECÍFICA POR ROL ==========
case "$ROLE" in
    master)
        cat > /etc/mysql/mariadb.conf.d/60-replication.cnf << CNF
[mariadb]
server_id = $NODE_ID
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
binlog_annotate_row_events = ON
sync_binlog = 1
gtid_domain_id = 1
log_slave_updates = ON
skip_name_resolve = ON
CNF
        ;;
    slave)
        cat > /etc/mysql/mariadb.conf.d/60-replication.cnf << CNF
[mariadb]
server_id = $NODE_ID
relay_log = /var/log/mysql/mariadb-relay-bin
relay_log_index = /var/log/mysql/mariadb-relay-bin.index
relay_log_purge = ON
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
binlog_annotate_row_events = ON
log_slave_updates = ON
gtid_domain_id = 1
read_only = ON
skip_name_resolve = ON
CNF
        ;;
    multimaster)
        cat > /etc/mysql/mariadb.conf.d/60-replication.cnf << CNF
[mariadb]
server_id = $NODE_ID
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
binlog_annotate_row_events = ON
gtid_domain_id = 1
log_slave_updates = ON
skip_name_resolve = ON
CNF
        ;;
    shard)
        cat > /etc/mysql/mariadb.conf.d/60-replication.cnf << CNF
[mariadb]
server_id = $NODE_ID
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
binlog_annotate_row_events = ON
gtid_domain_id = 1
log_slave_updates = ON
skip_name_resolve = ON
CNF
        ;;
    spider)
        echo "[$NODE_NAME] Instalando plugin MariaDB Spider..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-plugin-spider 2>/dev/null || true
        cat > /etc/mysql/mariadb.conf.d/60-replication.cnf << CNF
[mariadb]
server_id = $NODE_ID
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M
binlog_annotate_row_events = ON
gtid_domain_id = 1
log_slave_updates = ON
skip_name_resolve = ON
plugin_load_add = ha_spider
CNF
        ;;
esac

# ========== PREPARAR DIRECTORIO DE LOGS ==========
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql
chmod 755 /var/log/mysql

# ========== REINICIAR MARIADB CON NUEVA CONFIG ==========
echo "[$NODE_NAME] Reiniciando MariaDB con configuración de rol..."
systemctl reset-failed mariadb 2>/dev/null || true
if ! systemctl restart mariadb; then
    echo "[$NODE_NAME] ERROR: MariaDB no arrancó. Diagnóstico:"
    journalctl -xeu mariadb.service --no-pager -n 30 2>/dev/null || true
    cat /var/log/mysql/mariadb.err 2>/dev/null || true
    echo "[$NODE_NAME] Reintentando con configuración mínima..."
    # Deshabilitar temporalmente skip_name_resolve si causa problemas
    sed -i '/skip_name_resolve/d' /etc/mysql/mariadb.conf.d/60-replication.cnf
    systemctl reset-failed mariadb 2>/dev/null || true
    systemctl restart mariadb
fi
sleep 3

# ========== SCRIPTS SQL / SYNC FROM MASTER ==========
SQL_DIR="/vagrant/sql"

if [ "$ROLE" = "slave" ] || [ "$ROLE" = "multimaster" ]; then
    # Sync database from master instead of running local data scripts
    # (evita Duplicate entry 1062 al replicar datos ya insertados localmente)
    if [ -n "$MASTER_IP" ]; then
        echo "[$NODE_NAME] Sincronizando base de datos desde maestro $MASTER_IP..."

        # Wait for master MySQL to be reachable (up to 60s)
        for i in $(seq 1 30); do
            if mysqladmin ping -h "$MASTER_IP" -u root -p"$MARIADB_ROOT_PASSWORD" --silent 2>/dev/null; then
                break
            fi
            sleep 2
        done

        # Lock master for consistent snapshot
        mysql -h "$MASTER_IP" -u root -p"$MARIADB_ROOT_PASSWORD" -e "FLUSH TABLES WITH READ LOCK" 2>/dev/null

        # Get GTID position from master (before dump, while locked)
        MASTER_GTID=$(mysql -h "$MASTER_IP" -u root -p"$MARIADB_ROOT_PASSWORD" -NBe "SELECT @@gtid_current_pos" 2>/dev/null | tail -1)

        # Dump lab_bdd from master
        if mysqldump -h "$MASTER_IP" -u root -p"$MARIADB_ROOT_PASSWORD" \
            --databases lab_bdd --routines --triggers --events \
            > /tmp/sync.sql 2>/dev/null; then

            # Unlock master
            mysql -h "$MASTER_IP" -u root -p"$MARIADB_ROOT_PASSWORD" -e "UNLOCK TABLES" 2>/dev/null

            # Restore data from master
            mysql -u root -p"$MARIADB_ROOT_PASSWORD" < /tmp/sync.sql

            # Set GTID so slave skips already-applied transactions
            if [ -n "$MASTER_GTID" ]; then
                mysql -u root -p"$MARIADB_ROOT_PASSWORD" -e "SET GLOBAL gtid_slave_pos='$MASTER_GTID';" 2>/dev/null
                echo "[$NODE_NAME] GTID establecido: $MASTER_GTID"
            fi

            echo "[$NODE_NAME] Sincronización completada desde $MASTER_IP"
        else
            mysql -h "$MASTER_IP" -u root -p"$MARIADB_ROOT_PASSWORD" -e "UNLOCK TABLES" 2>/dev/null
            echo "[$NODE_NAME] AVISO: No se pudo conectar al maestro, usando scripts locales como fallback..."
            if [ -d "$SQL_DIR" ]; then
                for f in "$SQL_DIR"/*.sql; do
                    [ -f "$f" ] && mysql -u root -p"$MARIADB_ROOT_PASSWORD" < "$f" 2>/dev/null || true
                done
            fi
        fi
        rm -f /tmp/sync.sql

        # Create application users locally (03-users.sql handles IF NOT EXISTS)
        if [ -f "$SQL_DIR/03-users.sql" ]; then
            mysql -u root -p"$MARIADB_ROOT_PASSWORD" < "$SQL_DIR/03-users.sql"
        fi
    fi
else
    # For master, shard, spider: run local SQL scripts
    if [ -d "$SQL_DIR" ]; then
        echo "[$NODE_NAME] Ejecutando scripts SQL desde $SQL_DIR..."
        for f in "$SQL_DIR"/*.sql; do
            if [ -f "$f" ]; then
                BASENAME=$(basename "$f")
                SKIP=0

                case "$BASENAME" in
                    02-data.sql)
                        # Data completo solo en master; shards/spider usan scripts específicos
                        if [ "$ROLE" != "master" ]; then
                            echo "     (saltado $BASENAME, solo master)"
                            SKIP=1
                        fi
                        ;;
                    04-data-shard-a.sql)
                        if [ "$ROLE" != "shard" ] || [ "$NODE_NAME" != "bdd-nodo04" ]; then
                            echo "     (saltado $BASENAME, solo shard A)"
                            SKIP=1
                        fi
                        ;;
                    04-data-shard-b.sql)
                        if [ "$ROLE" != "shard" ] || [ "$NODE_NAME" != "bdd-nodo05" ]; then
                            echo "     (saltado $BASENAME, solo shard B)"
                            SKIP=1
                        fi
                        ;;
                    04-spider-setup.sql)
                        if [ "$ROLE" != "spider" ]; then
                            echo "     (saltado $BASENAME, solo spider)"
                            SKIP=1
                        fi
                        ;;
                    05-particionamiento.sql | check-*.sql | fix-*.sql | test-*.sql)
                        echo "     (saltado $BASENAME, demo/verificacion/fix)"
                        SKIP=1
                        ;;
                esac

                if [ "$SKIP" -eq 0 ]; then
                    echo "  -> $BASENAME"
                    mysql -u root -p"$MARIADB_ROOT_PASSWORD" < "$f"
                fi
            fi
        done
    else
        echo "[$NODE_NAME] AVISO: No se encontró $SQL_DIR"
    fi
fi

# ========== USUARIO DE REPLICACIÓN (solo en maestro) ==========
if [ "$ROLE" = "master" ]; then
    echo "[$NODE_NAME] Creando usuario de replicación..."
    mysql -u root -p"$MARIADB_ROOT_PASSWORD" <<SQL
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY '$REPL_PASSWORD';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;
SQL
fi

# ========== CONFIGURAR REPLICACIÓN (esclavo / multimaster) ==========
if [ "$ROLE" = "slave" ] && [ -n "$MASTER_IP" ]; then
    echo "[$NODE_NAME] Configurando replicación esclavo -> $MASTER_IP..."
    sleep 5
    mysql -u root -p"$MARIADB_ROOT_PASSWORD" <<SQL
CHANGE MASTER TO
  MASTER_HOST = '$MASTER_IP',
  MASTER_PORT = 3306,
  MASTER_USER = 'repl_user',
  MASTER_PASSWORD = '$REPL_PASSWORD',
  MASTER_USE_GTID = slave_pos;
START SLAVE;
SQL
fi

if [ "$ROLE" = "multimaster" ] && [ -n "$MASTER_IP" ]; then
    echo "[$NODE_NAME] Configurando replicación multi-maestro -> $MASTER_IP..."
    sleep 5
    mysql -u root -p"$MARIADB_ROOT_PASSWORD" <<SQL
CHANGE MASTER TO
  MASTER_HOST = '$MASTER_IP',
  MASTER_PORT = 3306,
  MASTER_USER = 'repl_user',
  MASTER_PASSWORD = '$REPL_PASSWORD',
  MASTER_USE_GTID = slave_pos;
START SLAVE;
SQL
fi

# ========== VERIFICAR ESTADO ==========
if [ "$ROLE" = "master" ]; then
    echo "[$NODE_NAME] Estado del maestro:"
    mysql -u root -p"$MARIADB_ROOT_PASSWORD" -e "SHOW MASTER STATUS\G"
fi

if [ "$ROLE" = "slave" ] || [ "$ROLE" = "multimaster" ]; then
    echo "[$NODE_NAME] Estado del esclavo:"
    mysql -u root -p"$MARIADB_ROOT_PASSWORD" -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_IO_Error|Last_SQL_Error"
fi

touch "$MARKER"
echo "=== [$NODE_NAME] Rol $ROLE configurado correctamente ==="

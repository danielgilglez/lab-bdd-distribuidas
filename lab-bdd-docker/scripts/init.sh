#!/bin/bash
set -e

NODE_NAME=${NODE_NAME:-bdd-nodo00}
NODE_IP=${NODE_IP:-127.0.0.1}
NODE_ID=${NODE_ID:-0}
ROLE=${ROLE:-standalone}
MASTER_IP=${MASTER_IP:-}
REPL_PASSWORD=${REPL_PASSWORD:-ReplUser_2025!}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-LabAdmin_2025!}

echo "=== Inicializando nodo: $NODE_NAME (ID: $NODE_ID, Rol: $ROLE) ==="

echo "$NODE_NAME" > /etc/hostname
hostname "$NODE_NAME"

echo "127.0.0.1 localhost" > /etc/hosts
echo "::1 localhost ip6-localhost ip6-loopback" >> /etc/hosts
echo "127.0.1.1 $NODE_NAME" >> /etc/hosts
echo "192.168.56.101 bdd-nodo01" >> /etc/hosts
echo "192.168.56.102 bdd-nodo02" >> /etc/hosts
echo "192.168.56.103 bdd-nodo03" >> /etc/hosts
echo "192.168.56.104 bdd-nodo04" >> /etc/hosts
echo "192.168.56.105 bdd-nodo05" >> /etc/hosts
echo "192.168.56.106 bdd-nodo06" >> /etc/hosts

case "$ROLE" in
  master)
    echo "Configurando como MAESTRO (server_id=$NODE_ID)..."
    cp /config/nodo01/60-replication-master.cnf /etc/mysql/mariadb.conf.d/
    sed -i "s/server_id = 1/server_id = $NODE_ID/" /etc/mysql/mariadb.conf.d/60-replication-master.cnf
    ;;
  slave)
    echo "Configurando como ESCLAVO (server_id=$NODE_ID)..."
    cp /config/nodo02/60-replication-slave.cnf /etc/mysql/mariadb.conf.d/
    sed -i "s/server_id = 2/server_id = $NODE_ID/" /etc/mysql/mariadb.conf.d/60-replication-slave.cnf
    ;;
  multimaster)
    echo "Configurando como MULTI-MAESTRO (server_id=$NODE_ID)..."
    cp /config/nodo03/60-replication-multimaster.cnf /etc/mysql/mariadb.conf.d/
    sed -i "s/server_id = 3/server_id = $NODE_ID/" /etc/mysql/mariadb.conf.d/60-replication-multimaster.cnf
    ;;
  shard)
    echo "Configurando como SHARD (server_id=$NODE_ID)..."
    cp /config/nodo04/60-shard.cnf /etc/mysql/mariadb.conf.d/
    sed -i "s/server_id = 4/server_id = $NODE_ID/" /etc/mysql/mariadb.conf.d/60-shard.cnf
    ;;
  spider)
    echo "Configurando como SPIDER COORDINADOR (server_id=$NODE_ID)..."
    cp /config/nodo06/60-spider.cnf /etc/mysql/mariadb.conf.d/
    sed -i "s/server_id = 6/server_id = $NODE_ID/" /etc/mysql/mariadb.conf.d/60-spider.cnf
    ;;
  standalone)
    echo "Configurando como STANDALONE (server_id=$NODE_ID)..."
    ;;
esac

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Inicializando base de datos MariaDB por primera vez..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

echo "Iniciando MariaDB temporal para configuración..."
mysqld_safe --skip-networking &
MYSQL_PID=$!
sleep 5

if [ ! -f "/var/lib/mysql/.init-complete" ]; then
    echo "Ejecutando scripts de inicialización desde /docker-entrypoint-initdb.d/..."
    for f in /docker-entrypoint-initdb.d/*.sql; do
        if [ -f "$f" ]; then
            echo "Ejecutando $f..."
            mysql -u root < "$f"
        fi
    done

    if [ "$ROLE" = "master" ]; then
        echo "Creando usuario de replicación en el maestro..."
        mysql -u root -e "
          CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY '$REPL_PASSWORD';
          GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
          FLUSH PRIVILEGES;
        "
    fi

    touch /var/lib/mysql/.init-complete
fi

if [ "$ROLE" = "slave" ] && [ -n "$MASTER_IP" ]; then
    echo "Configurando replicación esclavo hacia $MASTER_IP..."
    mysql -u root -e "
      CHANGE MASTER TO
        MASTER_HOST = '$MASTER_IP',
        MASTER_PORT = 3306,
        MASTER_USER = 'repl_user',
        MASTER_PASSWORD = '$REPL_PASSWORD',
        MASTER_USE_GTID = slave_pos;
      START SLAVE;
    "
fi

if [ "$ROLE" = "multimaster" ] && [ -n "$MASTER_IP" ]; then
    echo "Configurando replicación multi-maestro con $MASTER_IP..."
    mysql -u root -e "
      CHANGE MASTER TO
        MASTER_HOST = '$MASTER_IP',
        MASTER_PORT = 3306,
        MASTER_USER = 'repl_user',
        MASTER_PASSWORD = '$REPL_PASSWORD',
        MASTER_USE_GTID = slave_pos;
      START SLAVE;
    "
fi

echo "Deteniendo MariaDB temporal..."
mysqladmin -u root shutdown
wait $MYSQL_PID
sleep 2

echo "=== Nodo $NODE_NAME inicializado correctamente ==="
echo "Iniciando MariaDB en primer plano..."

exec mysqld_safe

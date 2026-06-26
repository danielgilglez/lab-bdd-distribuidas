#!/bin/bash
set -e

MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-LabAdmin_2025!}
MARKER="/var/lib/mysql/.provision-base-complete"

if [ -f "$MARKER" ]; then
    echo "[BASE] Ya ejecutado, saltando."
    exit 0
fi

echo "=== [BASE] Creando usuario bddadmin ==="
id -u bddadmin &>/dev/null || useradd -m -s /bin/bash -G sudo bddadmin
echo "bddadmin:bddadmin" | chpasswd
mkdir -p /home/bddadmin/.ssh
cp /home/vagrant/.ssh/authorized_keys /home/bddadmin/.ssh/ 2>/dev/null || true
chown -R bddadmin:bddadmin /home/bddadmin/.ssh
chmod 700 /home/bddadmin/.ssh
chmod 600 /home/bddadmin/.ssh/authorized_keys
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo "bddadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/bddadmin
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || service ssh restart

echo "=== [BASE] Instalando MariaDB Server ==="
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq \
    mariadb-server \
    mariadb-client \
    curl \
    net-tools \
    iproute2 \
    iputils-ping \
    dnsutils \
    nano \
    sudo \
    openssh-server

apt-get clean -qq
rm -rf /var/lib/apt/lists/*

echo "=== [BASE] Configurando charset utf8mb4 ==="
cat > /etc/mysql/mariadb.conf.d/99-lab-charset.cnf << 'CNF'
[server]
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
[client]
default-character-set = utf8mb4
CNF

echo "=== [BASE] Configurando logging ==="
cat > /etc/mysql/mariadb.conf.d/99-lab-logs.cnf << 'CNF'
[mariadb]
slow_query_log = ON
slow_query_log_file = /var/log/mysql/mariadb-slow.log
long_query_time = 2
log_queries_not_using_indexes = ON
log_error = /var/log/mysql/mariadb.err
general_log = OFF
CNF

echo "=== [BASE] Habilitando bind-address 0.0.0.0 ==="
sed -i 's/^bind-address\s*=\s*127\.0\.0\.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

echo "=== [BASE] Configurando contraseña root ==="
systemctl restart mariadb
sleep 2

mysql -u root <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '$MARIADB_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

touch "$MARKER"
echo "=== [BASE] Provisionamiento base completado ==="

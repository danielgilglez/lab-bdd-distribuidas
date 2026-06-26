FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV MARIADB_ROOT_PASSWORD=LabAdmin_2025!
ENV MARIADB_VERSION=1:10.11.11-0ubuntu0.24.04.1

RUN apt-get update && \
    apt-get install -y \
        mariadb-server \
        mariadb-client \
        software-properties-common \
        curl \
        net-tools \
        iproute2 \
        iputils-ping \
        dnsutils \
        nano \
        sudo \
        openssh-server \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd && \
    mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

RUN mkdir -p /opt/lab_bdd_backups && \
    chmod 755 /opt/lab_bdd_backups

RUN rm -f /etc/mysql/mariadb.conf.d/99-lab-charset.cnf

COPY config/99-lab-charset.cnf /etc/mysql/mariadb.conf.d/99-lab-charset.cnf
COPY config/99-lab-logs.cnf /etc/mysql/mariadb.conf.d/99-lab-logs.cnf
COPY sql/ /docker-entrypoint-initdb.d/

COPY scripts/init.sh /usr/local/bin/init-node.sh
RUN chmod +x /usr/local/bin/init-node.sh

RUN sed -i 's/bind-address\s*=\s*127\.0\.0\.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf || \
    echo "bind-address = 0.0.0.0" >> /etc/mysql/mariadb.conf.d/50-server.cnf

EXPOSE 3306 22

ENTRYPOINT ["/usr/local/bin/init-node.sh"]
CMD ["mysqld_safe"]

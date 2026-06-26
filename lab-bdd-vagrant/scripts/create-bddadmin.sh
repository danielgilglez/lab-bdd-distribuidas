#!/bin/bash
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
echo "OK: bddadmin creado en $(hostname)"

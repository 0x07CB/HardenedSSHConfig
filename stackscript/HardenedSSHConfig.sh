#!/bin/bash


# <UDF name="ssh_port" label="Port SSH" default="22" example="22, 2222, etc">
# <UDF name="permit_root" label="Autoriser la connexion root" default="no" oneOf="yes,no">
# <UDF name="allow_password" label="Autoriser l'authentification par mot de passe" default="no" oneOf="yes,no">
# <UDF name="limited_user_name" label="Nom d'utilisateur pour la limitation de sudo" default="user">
# <UDF name="limited_user_password" label="Mot de passe pour l'utilisateur limité" default="password">


# Script to setup an SSH server with custom configurations 
#and additional services on Debian 12

# Exit immediately if a command exits with a non-zero status
set -e

# Update and upgrade system packages
apt-get update -y && \
    apt-get upgrade -y


# Backup the original SSHD configuration
if [ -f /etc/ssh/sshd_config ]; then
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.default
    echo "Backup of sshd_config created at /etc/ssh/sshd_config.default"
else
    echo "Error: SSH configuration file not found. Exiting."
    exit 1
fi


sed -i '1iProtocol 2' /etc/ssh/sshd_config

sed -i "s/^#Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config

sed -i -E 's/^#?(ChallengeResponseAuthentication) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(PubkeyAuthentication) .*/\1 yes/' /etc/ssh/sshd_config

sed -i -E "s/^#?(PermitRootLogin) .*/\1 ${PERMIT_ROOT}/" /etc/ssh/sshd_config

sed -i -E "s/^#?(PasswordAuthentication) .*/\1 ${ALLOW_PASSWORD}/" /etc/ssh/sshd_config

sed -i -E 's/^#?(Compression) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(GatewayPorts) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(AllowTcpForwarding) .*/\1 yes/' /etc/ssh/sshd_config

sed -i -E 's/^#?(AllowAgentForwarding) .*/\1 yes/' /etc/ssh/sshd_config

sed -i -E 's/^#?(UsePAM) .*/\1 yes/' /etc/ssh/sshd_config

sed -i -E 's/^#?(X11Forwarding) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(IgnoreRhosts) .*/\1 yes/' /etc/ssh/sshd_config

sed -i -E 's/^#?(HostbasedAuthentication) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(MaxSessions) .*/\1 6/' /etc/ssh/sshd_config

sed -i -E 's/^#?(MaxAuthTries) .*/\1 3/' /etc/ssh/sshd_config

sed -i -E 's/^#(AuthorizedKeysFile[[:space:]]+)/\1/' /etc/ssh/sshd_config

sed -i -E 's/^#?(LogLevel) .*/\1 VERBOSE/' /etc/ssh/sshd_config

sed -i -E 's/^#?(PrintLastLog) .*/\1 yes/' /etc/ssh/sshd_config

sed -i -E 's/^#?(TCPKeepAlive) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(PermitUserEnvironment) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(ClientAliveInterval) .*/\1 300/' /etc/ssh/sshd_config

sed -i -E 's/^#?(ClientAliveCountMax) .*/\1 0/' /etc/ssh/sshd_config

sed -i -E 's/^#?(UseDNS) .*/\1 no/' /etc/ssh/sshd_config

sed -i -E 's/^#?(PidFile) .*/\1 \/var\/run\/sshd.pid/' /etc/ssh/sshd_config

sed -i -E 's/^#?(MaxStartups) .*/\1 10:30:100/' /etc/ssh/sshd_config


# create a new user with name from UDF field limited_user_name and password from UDF field limited_user_password
useradd -m -s /bin/bash $LIMITED_USER_NAME
echo "${LIMITED_USER_NAME}:${LIMITED_USER_PASSWORD}" | chpasswd

# add the new user to the sudo group
usermod -aG sudo ${LIMITED_USER_NAME}

# in the home directory of the new user, create a .ssh directory (with chmod 700) and a authorized_keys file (with chmod 600)
mkdir -p /home/${LIMITED_USER_NAME}/.ssh
touch /home/${LIMITED_USER_NAME}/.ssh/authorized_keys
cat /root/.ssh/authorized_keys >> /home/${LIMITED_USER_NAME}/.ssh/authorized_keys
chown -R ${LIMITED_USER_NAME}:${LIMITED_USER_NAME} /home/${LIMITED_USER_NAME}/.ssh
sudo -u ${LIMITED_USER_NAME} chmod 700 /home/${LIMITED_USER_NAME}/.ssh
sudo -u ${LIMITED_USER_NAME} chmod 600 /home/${LIMITED_USER_NAME}/.ssh/authorized_keys


# Restart the SSH service to apply the changes
if systemctl restart sshd; then
    echo "SSH service restarted successfully."
else
    echo "Failed to restart SSH service. Check the configuration."
    exit 1
fi


# Install fail2ban 
apt-get install fail2ban -y

systemctl disable --now fail2ban

# Configure fail2ban to monitor the SSH service
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

touch /etc/fail2ban/jail.d/00-sshd.conf

touch /etc/fail2ban/jail.d/00-sshd.conf

cat << 'EOF' > /etc/fail2ban/jail.d/00-sshd.conf
[sshd]
enabled = true
bantime.increment = true
bantime = 1h
bantime.rndtime = 30m
maxretry = 5
bantime.multipliers = 1 12 24 168 336 672 1008 2016 4032
bantime.overalljails = true
mode   = normal
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

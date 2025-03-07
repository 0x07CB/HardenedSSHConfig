#!/bin/bash

# Validation des variables UDF
: "${SSH_PORT:?Erreur: la variable UDF 'ssh_port' (SSH_PORT) doit être définie.}"
: "${PERMIT_ROOT:?Erreur: la variable UDF 'permit_root' (PERMIT_ROOT) doit être définie.}"
: "${ALLOW_PASSWORD:?Erreur: la variable UDF 'allow_password' (ALLOW_PASSWORD) doit être définie.}"
: "${LIMITED_USER_NAME:?Erreur: la variable UDF 'limited_user_name' (LIMITED_USER_NAME) doit être définie.}"
: "${LIMITED_USER_PASSWORD:?Erreur: la variable UDF 'limited_user_password' (LIMITED_USER_PASSWORD) doit être définie.}"

# <UDF name="ssh_port" label="Port SSH" default="22" example="22, 2222, etc">
# <UDF name="permit_root" label="Autoriser la connexion root" default="no" oneOf="yes,no">
# <UDF name="allow_password" label="Autoriser l'authentification par mot de passe" default="no" oneOf="yes,no">
# <UDF name="limited_user_name" label="Nom d'utilisateur pour la limitation de sudo" default="user">
# <UDF name="limited_user_password" label="Mot de passe pour l'utilisateur limité" default="password">

# Script pour configurer un serveur SSH avec des configurations personnalisées 
# et des services additionnels sur Debian 12

# Arrêter le script immédiatement en cas d'erreur
set -e
trap 'echo "Erreur : Une erreur est survenue à la ligne ${LINENO}. Veuillez vérifier la dernière commande exécutée." >&2' ERR

# Mise à jour et mise à niveau des paquets système
sudo apt-get update -y && sudo apt-get upgrade -y

# Sauvegarde de la configuration SSHD originale
if [ -f /etc/ssh/sshd_config ]; then
    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.default
    echo "Sauvegarde de sshd_config créée à /etc/ssh/sshd_config.default"
else
    echo "Erreur : fichier de configuration SSH introuvable. Arrêt du script."
    exit 1
fi

sudo sed -i '1iProtocol 2' /etc/ssh/sshd_config

sudo sed -i "s/^#Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(ChallengeResponseAuthentication) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(KbdInteractiveAuthentication) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(PubkeyAuthentication) .*/\1 yes/' /etc/ssh/sshd_config

sudo sed -i -E "s/^#?(PermitRootLogin) .*/\1 ${PERMIT_ROOT}/" /etc/ssh/sshd_config

sudo sed -i -E "s/^#?(PasswordAuthentication) .*/\1 ${ALLOW_PASSWORD}/" /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(Compression) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(GatewayPorts) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(AllowTcpForwarding) .*/\1 yes/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(AllowAgentForwarding) .*/\1 yes/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(UsePAM) .*/\1 yes/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(X11Forwarding) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(IgnoreRhosts) .*/\1 yes/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(HostbasedAuthentication) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(MaxSessions) .*/\1 6/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(MaxAuthTries) .*/\1 3/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#(AuthorizedKeysFile[[:space:]]+)/\1/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(LogLevel) .*/\1 VERBOSE/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(PrintLastLog) .*/\1 yes/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(TCPKeepAlive) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(PermitUserEnvironment) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(ClientAliveInterval) .*/\1 300/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(ClientAliveCountMax) .*/\1 0/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(UseDNS) .*/\1 no/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(PidFile) .*/\1 \/var\/run\/sshd.pid/' /etc/ssh/sshd_config

sudo sed -i -E 's/^#?(MaxStartups) .*/\1 10:30:100/' /etc/ssh/sshd_config

# Création d'un nouvel utilisateur avec le nom et le mot de passe spécifiés
sudo useradd -m -s /bin/bash "${LIMITED_USER_NAME}"
echo "${LIMITED_USER_NAME}:${LIMITED_USER_PASSWORD}" | sudo chpasswd

# Ajout du nouvel utilisateur au groupe sudo
sudo usermod -aG sudo "${LIMITED_USER_NAME}"

# Dans le répertoire personnel du nouvel utilisateur, création du dossier .ssh avec les permissions appropriées, et copie du fichier authorized_keys
sudo install -o "${LIMITED_USER_NAME}" -g "${LIMITED_USER_NAME}" -d -m 700 /home/"${LIMITED_USER_NAME}"/.ssh
sudo cp /root/.ssh/authorized_keys /home/"${LIMITED_USER_NAME}"/.ssh/authorized_keys
sudo chown "${LIMITED_USER_NAME}":"${LIMITED_USER_NAME}" /home/"${LIMITED_USER_NAME}"/.ssh/authorized_keys
sudo chmod 600 /home/"${LIMITED_USER_NAME}"/.ssh/authorized_keys

# Redémarrage du service SSH pour appliquer les modifications
if sudo systemctl restart ssh; then
    echo "Service SSH redémarré avec succès."
else
    echo "Échec du redémarrage du service SSH. Vérifiez la configuration."
    exit 1
fi

# Installation de fail2ban 
sudo apt-get install fail2ban -y

sudo systemctl disable --now fail2ban

# Configuration de fail2ban pour surveiller le service SSH
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sudo touch /etc/fail2ban/jail.d/00-sshd.conf

sudo tee /etc/fail2ban/jail.d/00-sshd.conf > /dev/null << EOF
[sshd]
enabled = true
bantime.increment = true
bantime = 1h
bantime.rndtime = 30m
maxretry = 5
bantime.multipliers = 1 12 24 168 336 672 1008 2016 4032
bantime.overalljails = true
mode   = normal
port    = ${SSH_PORT}
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

# Configuration de logencoding en utf-8 dans jail.local
sudo sed -i 's/^#\{0,1\}logencoding = .*/logencoding = utf-8/' /etc/fail2ban/jail.local

# Configuration de usedns sur yes dans jail.local
sudo sed -i 's/^#\{0,1\}usedns = .*/usedns = yes/' /etc/fail2ban/jail.local

# Configuration de backend sur systemd dans jail.local
sudo sed -i 's/^#\{0,1\}backend = .*/backend = systemd/' /etc/fail2ban/jail.local

# Décommenter et configurer allowipv6 sur yes dans fail2ban.conf
sudo sed -i 's/^#allowipv6 = auto/allowipv6 = yes/' /etc/fail2ban/fail2ban.conf

sudo systemctl enable --now fail2ban

sudo systemctl restart sshd

#!/usr/bin/env bash
GREEN="\e[32m"
BLUE="\e[34m"
ORANGE="\e[33m"
RED="\e[31m"
NC="\e[0m" # No Color

export DEBIAN_FRONTEND=noninteractive
export WSL_HOST_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | sed 's/\r//')
export USERPROFILE=$(cd /mnt/c/Windows/System32/ && cmd.exe "/c" "whoami" | sed -E s/'^.+\\([^\\]*)$'/'\1'/ | sed 's/\r//')
export USERPROFILEPATH=$(wslpath "$(wslvar USERPROFILE)" | sed 's/\r//')

##echo "## sources Ubuntu FR"
##sudo sed -i 's|http://security.ubuntu.com|https://fr.archive.ubuntu.com|g' /etc/apt/sources.list
##sudo sed -i 's|http://archive.ubuntu.com|https://fr.archive.ubuntu.com|g' /etc/apt/sources.list
##sudo sed -i 's|https://security.ubuntu.com|https://fr.archive.ubuntu.com|g' /etc/apt/sources.list
##sudo sed -i 's|https://archive.ubuntu.com|https://fr.archive.ubuntu.com|g' /etc/apt/sources.list
##
##echo "## Install Inetum Certificates"
##sudo mkdir -p /usr/share/ca-certificates/inetum
##sudo cp $USERPROFILEPATH/ca-certificates.crt /usr/share/ca-certificates/inetum
##sudo cp $USERPROFILEPATH/.ca-certificates/GFI_INFORMATIQUE_SA.crt /usr/share/ca-certificates/inetum
##sudo cp $USERPROFILEPATH/.ca-certificates/GFI_Informatique_OrlĂ©ans_Root_CA.crt /usr/share/ca-certificates/inetum
##sudo cp $USERPROFILEPATH/.ca-certificates/fwca.annuaire.groupe.local.crt /usr/share/ca-certificates/inetum
##sudo ln -sf /usr/share/ca-certificates/inetum/* /usr/local/share/ca-certificates/
##sudo update-ca-certificates
##
##
##
##
##echo "## Disable SSL verification (needed because of Inetum's palo alto proxy)"
##if [ -f /etc/apt/apt.conf.d/80ssl-exceptions ]; then
##	sudo touch /etc/apt/apt.conf.d/80ssl-exceptions
##fi
##sudo bash -c 'cat << EOF > /etc/apt/apt.conf.d/80ssl-exceptions
##Acquire::https::Verify-Peer "false";
##Acquire::https::Verify-Host "false";
##EOF'

# Get Windows host SSH key"
echo -e "${BLUE} Get Windows host SSH key ${NC}"
mkdir -p ~/.ssh
cp "$USERPROFILEPATH"/.ssh/* ~/.ssh

# Automate the copy of ssh key on each login
echo -e "${BLUE} Automate the copy of Windows host SSH key ${NC}"
cat << EOF >> ~/.bashrc

# overwrite local ssh keys with hosts
rm -rf ~/.ssh/*
cp ${USERPROFILEPATH}/.ssh/* ~/.ssh
chmod 600 ~/.ssh/*
EOF

# Set WSL HOST_IP as available variable
echo -e "${BLUE} Set WSL HOST_IP as available variable ${NC}"
cat << EOF >> ~/.bashrc

# WSl_HOST_IP for XDebug
export WSL_HOST_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

EOF

# Install Docker"
echo -e "${GREEN} Install Docker ${NC}"
sudo apt update
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo apt install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg2
source /etc/os-release
curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -
echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list

# Install Docker Engine
echo -e "${GREEN} Install Docker Engine ${NC}"
sudo apt-get update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Docker configuration
echo -e "${BLUE} Setup Docker configuration ${NC}"
sudo usermod -aG docker $USER
DOCKER_DIR=/mnt/wsl/shared-docker
mkdir -pm o=,ug=rwx "$DOCKER_DIR"
chgrp docker "$DOCKER_DIR"
sudo mkdir -p /etc/docker/
sudo bash -c 'cat << EOF > /etc/docker/daemon.json
{
  "hosts": ["unix:///mnt/wsl/shared-docker/docker.sock"],
  "iptables": false
}
EOF'

echo -e "${BLUE} Launch dockerd paswordless ${NC}"
echo '%docker ALL=(ALL) NOPASSWD: /usr/bin/dockerd' | sudo EDITOR='tee -a' visudo

echo -e "${BLUE} Make DockerD start automatically ${NC}"
cat <<EOF >> ~/.bashrc
# Launch dockerd automatically
DOCKER_DISTRO="$(cd /mnt/c/Windows/System32/ && cmd.exe "/c" "wsl -l -q" | sed 's/\x0//g' | sed 's/\r//')"
DOCKER_DIR=/mnt/wsl/shared-docker
DOCKER_SOCK="\$DOCKER_DIR/docker.sock"
export DOCKER_HOST="unix://\$DOCKER_SOCK"
if [ ! -S "$DOCKER_SOCK" ]; then
    mkdir -pm o=,ug=rwx "\$DOCKER_DIR"
    chgrp docker "\$DOCKER_DIR"
    /mnt/c/Windows/System32/wsl.exe -d \$DOCKER_DISTRO sh -c "nohup sudo -b dockerd < /dev/null > \$DOCKER_DIR/dockerd.log 2>&1"
fi
EOF

echo -e "${GREEN} Install docker-compose ${NC}"
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Installation de DOCKER DEV BOX
echo -e "${GREEN} Installation de DOCKER DEV BOX ${NC}"
curl -L https://github.com/inetum-orleans/docker-devbox/raw/master/installer | bash

DOCKER_DEVBOX_HOME="${DOCKER_DEVBOX_HOME:-$HOME/.docker-devbox}"
DOCKER_DEVBOX_BIN="${DOCKER_DEVBOX_HOME}/bin"
export PATH="$DOCKER_DEVBOX_BIN:$PATH"

# Configuration globale DDB
echo -e "${BLUE} Configuration globale DDB ${NC}"
LOCAL_IP="${LOCAL_IP:=127.0.0.1}"
if [ -f $HOME/.docker-devbox/ddb.yaml ]; then
	touch $HOME/.docker-devbox/ddb.yaml
fi
cat <<EOF > $HOME/.docker-devbox/ddb.yaml
# =======================================================================
# Generated file by gfi-centre-ouest/docker-devbox-vagrant
# Do not modify. To override, create a ddb.local.yaml file.
# =======================================================================
docker:
  ip: ${LOCAL_IP}
  debug:
    host: ${WSL_HOST_IP}
EOF

# Configuration locale DDB
echo -e "${BLUE} Configuration locale DDB ${NC}"
if [ -f $HOME/.docker-devbox/ddb.local.yaml ]; then
	touch $HOME/.docker-devbox/ddb.local.yaml
fi
cat <<EOF > $HOME/.docker-devbox/ddb.local.yaml
certs:
  cfssl:
    server:
      host: cfssl.etudes.local
      port: 443
      ssl: false #change this to true if palo alto certificates anf GP issues are resolved
      verify_cert: false #change this to true if palo alto certificates anf GP issues are resolved
shell:
  aliases:
    dc: docker-compose
  global_aliases:
    - dc
EOF

# Replace DDB_HOST_IP BY WSL_HOST_IP for XDebug on every logging
echo -e "${BLUE} Replace DDB_HOST_IP BY WSL_HOST_IP for XDebug on every logging ${NC}"
cat <<EOF >> ~/.bashrc

# ddb xdebug HOST_IP
DDB_ACTIVATE_FILE=\$(ddb activate | cut -c 2-)
DDB_DOCKER_DEBUG_HOST=\`cat \$DDB_ACTIVATE_FILE | grep -oP '(?<=DDB_DOCKER_DEBUG_HOST=)\d+(\.\d+){3}'\`
sed -i "s|\${DDB_DOCKER_DEBUG_HOST}|\${WSL_HOST_IP}|" "\${HOME}/.docker-devbox/ddb.local.yaml"
EOF

# Install Azuredevops CLI
sudo apt-get update && sudo apt-get install -y curl apt-transport-https lsb-release gnupg
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc.gpg > /dev/null
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update && sudo apt-get install -y azure-cli

echo -e "${ORANGE}PLEASE FOLLOW STEPS DESCRIBED IN PROCEDURE AT LINK (click available) :"
echo -e "https://gfi-orleans.visualstudio.com/INETUM-Docker-Devbox-Install/_wiki/wikis/Docker%20Devbox%20Install/1355/INSTALL?anchor=installation-de-azure-cli-(dans-la-vm)"
echo -e "${NC}";

echo -e "${BLUE}#############################################################################"
echo -e "                  PLEASE LOG OUT AND reLOG IN (tips: type exit)                     "
echo -e "###############################################################################${NC}"


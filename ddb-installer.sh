#!/usr/bin/env bash
GREEN="\e[32m"
BLUE="\e[34m"
ORANGE="\e[33m"
RED="\e[31m"
NC="\e[0m" # No Color

echo -e "${GREEN} Add docker to systemd${NC}"
sudo cp /lib/systemd/system/docker.service /etc/systemd/system/
echo -e "${GREEN} Expose daemon docker ${NC}"
sudo sed -i 's/\ -H\ fd:\/\//\ -H\ fd:\/\/\ -H\ tcp:\/\/127.0.0.1:2375/g' /etc/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker.service

## Installation de DOCKER DEV BOX
echo -e "${GREEN} Install Docker DEV BOX ${NC}"
curl -L https://github.com/inetum-orleans/docker-devbox-ddb/releases/latest/download/ddb-linux -o ddb && chmod +x ddb
sudo mv ./ddb /usr/local/bin/ddb

export USERPROFILEPATH=$(wslpath "$(wslvar USERPROFILE)" | sed 's/\r//')
export WSL_HOST_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | sed 's/\r//')

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

# Configuration globale DDB
echo -e "${BLUE}Prepare the global configuration for DDB ${NC}"
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
echo -e "${BLUE} Prepare the local configuration for DDB ${NC}"
if [ -f $HOME/.docker-devbox/ddb.local.yaml ]; then
	touch $HOME/.docker-devbox/ddb.local.yaml
fi
cat <<EOF > $HOME/.docker-devbox/ddb.local.yaml
#certs:
#  cfssl:
#    server:
#      host: cfssl.etudes.local
#      port: 443
#      ssl: false #change this to true if palo alto certificates anf GP issues are resolved
#      verify_cert: false #change this to true if palo alto certificates anf GP issues are resolved
shell:
  aliases:
    dc: docker-compose
  global_aliases:
    - dc
EOF

echo -e "${BLUE} Start traefik and portainer ${NC}"
docker network create reverse-proxy
cd ~/.docker-devbox/traefik || exit
docker-compose up -d
cd ../portainer || exit
docker-compose up -d
cd ~ || exit

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


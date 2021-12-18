#!/usr/bin/env bash
GREEN="\e[32m"
BLUE="\e[34m"
ORANGE="\e[33m"
RED="\e[31m"
NC="\e[0m" # No Color

# Install Docker"
echo -e "${GREEN} Install Docker ${NC}"
sudo apt-get update
#sudo apt install --no-install-recommends apt-transport-https ca-certificates curl gnupg2 lsb-release -y
#OS_RELEASE=$(cat /etc/os-release | grep -w ID | sed 's/ID=//')
#curl -fsSL https://download.docker.com/linux/${OS_RELEASE}/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
#echo \
#  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/${OS_RELEASE} \
#  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release\
    -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### Install Docker Engine
echo -e "${GREEN} Install Docker Engine ${NC}"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

sleep 3s
echo -e "${GREEN} Install systemd on WSL2 ${NC}"
git clone https://github.com/DamionGans/ubuntu-wsl2-systemd-script.git
cd ubuntu-wsl2-systemd-script || exit
bash ubuntu-wsl2-systemd-script.sh

echo -e "${BLUE}#############################################################################"
echo -e "                  PLEASE LOG OUT, reLOG IN and run ddb-installer.sh                "
echo -e "###############################################################################${NC}"


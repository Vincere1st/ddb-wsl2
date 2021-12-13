#!/usr/bin/env bash
GREEN="\e[32m"
BLUE="\e[34m"
ORANGE="\e[33m"
NC="\e[0m" # No Color

#Install systemd in WSL linux system:
echo -e "${GREEN} Install systemd ${NC}"
sudo apt-get update
sudo apt install -yqq fontconfig daemonize
sudo cp ./00-wsl2-systemd.sh /etc/profile.d/

echo -e "${BLUE}##############################################################################"
echo -e "       PLEASE FOLLOW INSTRUCTION (read and retains before execute${NC}${ORANGE} 😉 ${NC}${BLUE} ):"
echo -e "                          type exit for close ubuntu"
echo -e "                          and relaunch ubuntu  and type password"
echo -e "       and launch the second parts of installation by type bash install-ddb.sh "
echo -e "###############################################################################${NC}"


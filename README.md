cloner le projet dans home:

`git clone https://github.com/Vincere1st/ddb-wsl2.git`

`cd ddb-wsl2`

`bash docker-installer.sh`

à la fin faire un exit et relancer ubuntu

`cd ddb-wsl2`

`bash ddb-installer.sh`

faire de nouveau un exit et relancer ubuntu

`cd .docker-devbox/traefik`

`docker network create reverse-proxy`

`docker-compose up -d`

`cd ../portainer`

`docker-compose up -d`

ajouter au hosts windows 

127.0.0.1 portainer.test
127.0.0.1 traefik.test

go to chrome and go to https://traefik.test or https://portainer.test

enjoy!
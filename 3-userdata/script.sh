#!/bin/bash

# CONFIGURAÇÕES/VARIÀVEIS
EFS_DNS="fs-XXXXXXXX.efs.REGIAO.amazonaws.com"
DB_HOST="seu-endpoint-rds.amazonaws.com":3306
DB_USER="nome-de-usuario"
DB_PASSWORD="sua-senha"
DB_NAME="nome-do-banco"

# ATUALIZAR SISTEMA E INSTALAR DEPENDÊNCIAS
sudo apt update && sudo apt upgrade -y
sudo apt install -y nfs-common docker.io curl

# HABILITAR DOCKER
sudo systemctl enable docker
sudo systemctl start docker

# INSTALAR DOCKER COMPOSE
sudo curl -SL https://github.com/docker/compose/releases/download/v2.35.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# MONTAR EFS
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1 ${EFS_DNS}:/ /mnt/efs
sudo mkdir -p /mnt/efs/wordpress

# AJUSTAR PERMISSÕES DO EFS PARA O CONTAINER WORDPRESS
sudo chown -R 33:33 /mnt/efs/wordpress
sudo chmod -R 775 /mnt/efs/wordpress

# CRIAR DIRETÓRIO DA APLICAÇÃO
sudo mkdir -p /home/ubuntu/app-wordpress
cd /home/ubuntu/app-wordpress

# CRIAR docker-compose.yml
cat <<EOF | sudo tee docker-compose.yml
services:
  wordpress:
    image: wordpress:latest
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: \${WORDPRESS_DB_HOST}
      WORDPRESS_DB_USER: \${WORDPRESS_DB_USER}
      WORDPRESS_DB_PASSWORD: \${WORDPRESS_DB_PASSWORD}
      WORDPRESS_DB_NAME: \${WORDPRESS_DB_NAME}
    volumes:
      - /mnt/efs/wordpress:/var/www/html
EOF

# CRIAR .env
cat <<EOF | sudo tee .env
WORDPRESS_DB_HOST=${DB_HOST}
WORDPRESS_DB_USER=${DB_USER}
WORDPRESS_DB_PASSWORD=${DB_PASSWORD}
WORDPRESS_DB_NAME=${DB_NAME}
EOF

# RODAR/SUBIR APLICAÇÃO
sudo docker-compose up -d
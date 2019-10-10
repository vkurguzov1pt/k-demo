#!/bin/bash

sudo apt-get update
sudo apt-get install python-minimal docker.io docker-compose -y
sudo apt install software-properties-common -y
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt install ansible -y
sudo mkdir k-nginx
sudo echo "Hello, i am Nginx on instance: " >> k-nginx/index.html
sudo curl http://169.254.169.254/latest/meta-data/instance-id >> k-nginx/index.html
sudo touch k-nginx/Dockerfile
sudo tee -a k-nginx/Dockerfile > /dev/null <<EOT
FROM nginx

COPY index.html /usr/share/nginx/html

EXPOSE 80
EOT
sudo touch k-nginx/docker-compose.yml
sudo tee -a k-nginx/docker-compose.yml > /dev/null <<EOT
version: '3'
services:
        my_nginx:
                build: .
                ports:
                        - "80:80"
EOT
sleep 60
cd k-nginx && sudo docker-compose up

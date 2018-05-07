#!/bin/bash
sudo yum update -y

# Install packages to allow apt to use a repository over HTTPS:
sudo yum install -y  \
    postgresql95.x86_64 \	
    apt-transport-https \
    curl \
    software-properties-common


sudo yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

# set up the stable repository.
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo


# install docker
sudo yum update -y
#sudo yum install -y docker-ce docker-compose
sudo yum install -y docker

sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# give ubuntu permissions to execute docker
sudo usermod -aG docker $(whoami)

sudo service docker start

sudo /usr/local/bin/docker-compose -f /tmp/kafka-manager-docker-compose.yml up -d
sudo /usr/local/bin/docker-compose -f /tmp/kafka-topics-ui-docker-compose.yml up -d
sudo /usr/local/bin/docker-compose -f /tmp/zoonavigator-docker-compose.yml up -d




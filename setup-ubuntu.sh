#!/usr/bin/env bash
set -e



# Set up Docker APT source:

sudo apt-get update
sudo apt-get install -y \
  apt-transport-https \
  ca-certificates \

sudo apt-key adv \
  --keyserver 'hkp://p80.pool.sks-keyservers.net:80' \
  --recv-keys '58118E89F3A912897C070ADBF76221572C52609D' \

sudo tee /etc/apt/sources.list.d/docker.list \
  <<< "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main"



# Install Docker, DNS server:

# python-ipaddress: see https://github.com/docker/compose/issues/3525
sudo apt-get update
sudo apt-get install -y \
  python-ipaddress \
  docker-engine \
  linux-image-extra-virtual \
  dnsmasq \

# Install Vagrant:
curl -L -O 'https://releases.hashicorp.com/vagrant/1.8.5/vagrant_1.8.5_x86_64.deb' && sudo dpkg -i 'vagrant_1.8.5_x86_64.deb'

# Set up DNS:
sudo tee /etc/dnsmasq.d/channel-corp <<EOF
server=/cdm.channel-corp.com/8.8.8.8

server=/channel-corp.com/10.10.4.100
server=/channel-corp.com/10.10.4.101

server=/channelcorp.com/10.10.4.100
server=/channelcorp.com/10.10.4.101

server=/channelauction.com/10.10.4.100
server=/channelauction.com/10.10.4.101

server=/auction.local/10.10.4.100
server=/auction.local/10.10.4.101

address=/cs.enterprise.com/127.0.0.1
address=/cd.enterprise.com/127.0.0.1
EOF

sudo service dnsmasq restart

# Install Docker Compose:
sudo sh -c 'curl --retry 5 -L https://github.com/docker/compose/releases/download/1.8.0/run.sh > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose'

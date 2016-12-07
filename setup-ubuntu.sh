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

sudo apt-get update
sudo apt-get install -y \
  docker-engine \
  linux-image-extra-virtual \
  dnsmasq \

# python-ipaddress: see https://github.com/docker/compose/issues/3525
sudo apt-get install -y python-ipaddress || true

# Install Docker:
sudo adduser "${USER}" docker
sudo sh -c 'curl --retry 5 -L https://github.com/docker/compose/releases/download/1.9.0/run.sh > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose'

# Remove leftover dnsmasq configuration files from old versions of this script:
sudo rm -f '/etc/dnsmasq.d/'{'docker','interfaces'}

# Set up a local DNS forwarding server on the current host.  This server will be
# in charge of DNS resolution for all locally executed applications as well as
# any Docker containers managed by this host, as it will be available on the
# host's loopback interface as well as the host's address on the Docker bridge
# network interface.
#
# The no-resolv option makes the local dnsmasq instance ignore the pre-existing
# DNS servers defined in /etc/resolv.conf at the time the dnsmasq server starts,
# which makes it rely instead on its configuration files to find suitable back
# ends for each query it receives.
sudo tee '/etc/dnsmasq.d/basic' <<EOF
no-resolv
bind-dynamic
EOF

# Use the Google public DNS servers as the default back ends for DNS queries in
# regions of the DNS namespace with no otherwise specified back end servers:
sudo tee '/etc/dnsmasq.d/google' <<EOF
server=8.8.8.8
server=8.8.4.4
EOF

# If any dnsmasq configuration files enable the bind-interfaces option, it will
# conclict with 
for file in /etc/dnsmasq.d/*
do
  sed -i -e 's/^\s*bind-interfaces\s*\(#.*\)\?$/# &/' "${file}"
done

# Set up local DNS for Channel VPN:
sudo tee '/etc/dnsmasq.d/channel-corp' <<EOF
server=/cdm.channel-corp.com/8.8.8.8
server=/r2.auction.com/8.8.8.8

server=/github.channel-corp.com/8.8.8.8

server=/channel-corp.com/10.3.10.23
server=/channel-corp.com/10.3.10.24

server=/channelcorp.com/10.3.10.23
server=/channelcorp.com/10.3.10.24

server=/channelauction.com/10.3.10.23
server=/channelauction.com/10.3.10.24

server=/auction.local/10.3.10.23
server=/auction.local/10.3.10.24

address=/cs.enterprise.com/127.0.0.1
address=/cd.enterprise.com/127.0.0.1
EOF

# Disable Network Manager dnsmasq instances:
sudo sed -i '/etc/NetworkManager/NetworkManager.conf' -e 's/^dns=dnsmasq$/#&/'
sudo rm -f '/etc/dnsmasq.d/network-manager'
sudo pkill -f 'dnsmasq.*NetworkManager'

# Reload local DNS configuration:
sudo service dnsmasq restart

# Make name lookups for .local domains not go through mDNS as they should, and hit DNS instead, as domains in auction.local are expected to resolve through the Channel internal DNS servers (in violation of RFC 6762 — be warned this breaks mDNS):
sudo tee '/etc/nsswitch.conf' <<EOF
passwd:         compat
group:          compat
shadow:         compat
gshadow:        files

hosts:          files dns [NOTFOUND=return] mdns4_minimal
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF

# Configure Docker daemon:
sudo tee '/etc/docker/daemon.json' <<EOF
{
  "bip": "172.17.0.1/24",
  "dns": ["172.17.0.1"],
  "insecure-registries": [
    "registry.prod.auction.local:5000"
  ]
}
EOF

# Reload Docker daemon configuration:
sudo systemctl daemon-reload
sudo service docker restart

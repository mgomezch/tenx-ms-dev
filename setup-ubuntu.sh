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



# Install Docker Engine and the local DNS forwarding server dnsmasq:
sudo apt-get update
sudo apt-get install -y \
  docker-engine \
  linux-image-extra-virtual \
  dnsmasq \

# Fix python-ipaddress in Ubuntu 16.04, see
# https://github.com/docker/compose/issues/3525
sudo apt-get install -y python-ipaddress || true

# Install Docker Compose through Docker:
sudo sh -c 'curl --retry 5 -L https://github.com/docker/compose/releases/download/1.13.0/run.sh > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose'

# Allow the current user to command the Docker daemon:
sudo adduser "${USER}" docker

# Remove leftover dnsmasq configuration files from old versions of this script:
sudo rm -f '/etc/dnsmasq.d/'{'docker','interfaces','channel-corp'}

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
#
# The bind-dynamic option makes the local dnsmasq instance bind separate sockets
# for each network interface, which is generally preferred, for security, to a
# single socket listening on the wildcard address that relies on dnsmasq to
# exclude unwanted requests in userspace.  The bind-address option, which is
# mutually exclusive with the bind-dynamic option, also enables this behavior,
# but will additionally adjust its set of listening sockets automatically on
# network interface status changes, so it can start listening automatically on
# network interfaces enabled after the dnsmasq daemon starts.  This is desired
# since Docker creates network interfaces dynamically.
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
# conclict with the bind-dynamic option specified in the basic configuration.
for file in /etc/dnsmasq.d/*
do
  sudo sed -i -e 's/^\s*bind-interfaces\s*\(#.*\)\?$/# &/' "${file}"
done

# This configures the local DNS forwarding server to use certain specific back
# end DNS servers for certain domain names.  Domains handled by private DNS
# servers should be resolved using those instead of the public Internet DNS
# infrastructure, but domains that can be resolved by the public DNS should not
# be resolved with private servers, as those would only be available if a link
# to the proper VPN is online.
#
# TODO: This file should be generated dynamically on connection to the Ten-X VPN
# using the DNS IP addresses provided by DHCP.
sudo tee '/etc/dnsmasq.d/tenx' <<EOF

# VPN endpoints should be resolved through the public DNS, as they have to be
# resolved before any VPN link is established.
server=/cdm.channel-corp.com/8.8.8.8
server=/r2.auction.com/8.8.8.8

# Some specific domains are inside namespaces handled by private DNS servers but
# can also be resolved using public DNS servers.  Public resolution is preferred
# for these as they will not fail to resolve when VPN links are offline.
server=/github.channel-corp.com/8.8.8.8

# For any other domain in a namespace known to be handled by private DNS servers
# inside a VPN, use the well-known private DNS server VPN IP addresses as back
# ends for domain name resolution.  Note it is not possible to know the full set
# of such domain names in advance, so these are just some well-known roots.

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

server=/ten-x.io/10.3.10.23
server=/ten-x.io/10.3.10.24

EOF

# Disable Network Manager dnsmasq instances, as they could interfere with the
# dnsmasq configuration used by Docker containers.
sudo sed -i '/etc/NetworkManager/NetworkManager.conf' -e 's/^dns=dnsmasq$/#&/'
sudo rm -f '/etc/dnsmasq.d/network-manager'
sudo pkill -f 'dnsmasq.*NetworkManager'

# Reload local DNS configuration:
sudo service dnsmasq restart

# Make name lookups for .local domains not go through mDNS as they should, and
# hit DNS instead, as domains in auction.local are expected to resolve through
# the Ten-X internal DNS servers.  This is necessary because the Ten-X internal
# domain name allocation scheme violates RFC 6762 requirements by using the
# reserved .local top-level domain for a purpose other than mDNS, but the Name
# Service Switch configuration that comes by default with any reasonably modern
# system will come configured to use mDNS for domains under the .local TLD.
# Note that this may break mDNS and it may direct mDNS queries to public DNS,
# which may have an undesirable privacy impact.
sudo tee '/etc/nsswitch.conf' <<EOF
passwd:         compat
group:          compat
shadow:         compat
gshadow:        files

hosts:          files dns [NOTFOUND=continue] mdns4_minimal
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
EOF

# Configure the Docker daemon to use a specific address range for its default
# docker0 bridge network interface and give the Docker host a specific address
# within that range.  Additionally, configure containers managed by Docker to
# use the Docker host as a DNS server; this should allow them to hit the dnsmasq
# instance running on the Docker host, which in turn allows them to resolve and
# access private domain names in a VPN.
# TODO: expand comment
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

#!/usr/bin/env bash

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
# ruby-dev: required for Vagrant Landrush plugin
sudo apt-get update
sudo apt-get install -y \
  python-ipaddress \
  docker-engine \
  linux-image-extra-virtual \
  dnsmasq \
  ruby-dev \

# Install Vagrant:
curl -L -O 'https://releases.hashicorp.com/vagrant/1.8.5/vagrant_1.8.5_x86_64.deb' && sudo dpkg -i 'vagrant_1.8.5_x86_64.deb'

# Set up DNS:
sudo tee /etc/dnsmasq.d/channel-corp <<EOF
server=/cdm.channel-corp.com/8.8.8.8
server=/channel-corp.com/10.10.4.100
server=/channel-corp.com/10.10.4.101
server=/channelcorp.com/10.10.4.100
server=/channelcorp.com/10.10.4.101
server=/auction.local/10.10.4.100
server=/auction.local/10.10.4.101
address=/cs.enterprise.com/127.0.0.1
address=/cd.enterprise.com/127.0.0.1
EOF

# The Vagrant Landrush plugin restarts dnsmasq when the machine is brought up; this avoids blocking on password prompt:
sudo tee /etc/sudoers.d/restart-dnsmasq <<< '%sudo ALL=(ALL) NOPASSWD: /usr/sbin/service dnsmasq restart'
sudo chmod 400 /etc/sudoers.d/restart-dnsmasq

sudo service dnsmasq restart

# Install Docker Compose:
sudo sh -c 'curl --retry 5 -L https://github.com/docker/compose/releases/download/1.8.0/run.sh > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose'



# Set up the Landrush plugin for Vagrant:

vagrant plugin install landrush
sed -i -e 's/"8\.8\.8\.8"/"127.0.0.1"/' ~/.vagrant.d/data/landrush/config.json

# See https://github.com/vagrant-landrush/landrush/issues/248
for f in /opt/vagrant/embedded/gems/gems/vagrant-*/bin/vagrant; do patch "${f}"; break; done <<EOF
--- vagrant	2016-08-18 10:36:32.165942724 -0400
+++ vagrant-patched	2016-08-18 10:32:30.086721524 -0400
@@ -108,7 +108,11 @@
   require 'vagrant/util/platform'
 
   # Schedule the cleanup of things
-  at_exit(&Vagrant::Bundler.instance.method(:deinit))
+  if argv.include?("--no-cleanup") || ENV["VAGRANT_NO_CLEANUP"]
+    argv.delete("--no-cleanup")
+  else
+    at_exit(&Vagrant::Bundler.instance.method(:deinit))
+  end
 
   # Create a logger right away
   logger = Log4r::Logger.new("vagrant::bin::vagrant")
EOF

# Ensure the Landrush server is properly stopped:
vagrant landrush stop || true
rm -f ~/.vagrant.d/data/landrush/run/landrush.pid

# Start the Landrush server:
# Note: This command has to be executed manually sometimes if the Landrush server dies.
vagrant landrush start --no-cleanup

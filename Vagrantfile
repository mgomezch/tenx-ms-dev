# -*- mode: ruby -*-
# vi: set ft=ruby :

plugins=[
  'vagrant-docker-compose',
  'landrush',
]

unless (
  plugins
  .keep_if { |plugin| ! Vagrant.has_plugin? plugin }
  .each { |plugin| system "vagrant plugin install #{plugin}" }
  .empty?
)
  puts 'Dependencies installed, please try the command again.'
  exit
end



Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/trusty64'

  config.landrush.enabled = true

  config.vm.synced_folder "m2", "/vagrant/.m2"

  config.vm.provider 'virtualbox' do |vb|
    vb.cpus = 2
    vb.memory = '1024'
  end

  config.vm.provision 'shell', inline: <<-SHELL
    set -e
  # tee -a /etc/hosts <<< "$(route -n|sed -n -e 's/^0\.0\.0\.0  *\([^ ][^ ]*\) .* eth0/\1/p') host.vagrant.test"
    tee -a /etc/hosts <<< "10.0.2.2 host.vagrant.test"
    tee -a /etc/apt/apt.conf.d/01proxy <<< 'Acquire::http { Proxy "http://host.vagrant.test:3142"; };'
    apt-get update
    apt-get install -y dnsmasq
    tee /etc/dnsmasq.d/channel-vpn <<< '
      server=/cdm.channel-corp.com/8.8.8.8

      server=/channel-corp.com/10.10.4.100
      server=/channel-corp.com/10.10.4.101

      server=/channelcorp.com/10.10.4.100
      server=/channelcorp.com/10.10.4.101

      server=/auction.local/10.10.4.100
      server=/auction.local/10.10.4.101

      address=/cs.enterprise.com/127.0.0.1
      address=/cd.enterprise.com/127.0.0.1
    '
    service dnsmasq restart
  SHELL

  config.vm.provision :docker

  config.vm.provision 'shell', inline: <<-SHELL
    set -e
    tee -a /etc/default/docker <<< 'DOCKER_OPTS="--registry-mirror=http://host.vagrant.test:5000 --insecure-registry=registry.prod.auction.local:5000"'
    service docker restart
  SHELL

  config.vm.provision(
    :docker,
    images: [
      'maven:3.3.9-jdk-8',
      'jyore/flyway',
    ]
  )

  config.vm.provision(
    :docker_compose,
    yml: '/vagrant/docker-compose-vagrant.yml',
    rebuild: true,
    run: 'always',
  )
end

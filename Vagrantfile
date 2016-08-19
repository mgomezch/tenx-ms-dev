# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set up Vagrant plugins:

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

  config.vm.provider 'virtualbox' do |vb|
    vb.cpus = 2
    vb.memory = '1024'
  end



  # Install packages, set up DNS:

  config.vm.provision 'shell', inline: <<-SHELL
    set -e

    # Set up APT proxy:
  # tee -a /etc/hosts <<< "$(route -n|sed -n -e 's/^0\.0\.0\.0  *\([^ ][^ ]*\) .* eth0/\1/p') host.vagrant.test"
    tee -a /etc/hosts <<< "10.0.2.2 host.vagrant.test" # FIXME: This is VirtualBox-specific, but the above fails
    tee -a /etc/apt/apt.conf.d/01proxy <<< '
      Acquire::http { Proxy "http://host.vagrant.test:3142"; };
      Acquire::https::Proxy "false";
    '

    # Install basic development packages:
    apt-get update
    apt-get install -y dnsmasq zsh tmux git-all gnupg-agent

    # Set default user shell:
    chsh -s /bin/zsh vagrant

    # Set up local DNS server:
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

    # Install Docker-managed Docker Compose shim:
    sh -c 'curl --silent --retry 5 --location https://github.com/docker/compose/releases/download/1.8.0/run.sh > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose'
  SHELL



  # Set up default user environment:

  config.vm.synced_folder "m2", "/home/vagrant/.m2"
  config.vm.synced_folder "skel", "/home/vagrant/skel"

  config.vm.provision 'shell', privileged: false, inline: <<-SHELL
    set -e
    touch .hushlogin
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
    rm -f ~/.zshrc ~/.zshtheme
    find skel/ -mindepth 1 -maxdepth 1 -exec ln -s -t ~/ {} +
  SHELL



  # Set up Docker:

  config.vm.provision :docker

  # Make Docker use the registry mirror on the host:
  config.vm.provision 'shell', inline: <<-SHELL
    set -e
    tee -a /etc/default/docker <<< 'DOCKER_OPTS="--registry-mirror=http://host.vagrant.test:5000 --insecure-registry=registry.prod.auction.local:5000"'
    service docker restart
  SHELL

  # Pull development tool images:
  config.vm.provision(
    :docker,
    images: [
      'jyore/flyway',
      'maven:3.3.9-jdk-8',
    ]
  )

  # Bring up internal services specified in docker-compose-vagrant.yml
  config.vm.provision(
    :docker_compose,
    yml: '/vagrant/docker-compose-vagrant.yml',
    rebuild: true,
    run: 'always',
  )
end

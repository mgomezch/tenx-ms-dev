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
  config.vm.box = 'ubuntu/trusty64' # FIXME: Switch to ubuntu/xenial64 once this is resolved: https://bugs.launchpad.net/cloud-images/+bug/1605795

  config.vm.provider 'virtualbox' do |vb|
    vb.cpus = 2
    vb.memory = '1024'
  end



  config.landrush.enabled = true
  config.landrush.host_ip_address = "10.0.2.2" # FIXME: This is VirtualBox-specific



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

    # Set up Docker APT source:
    apt-get update
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    tee /etc/apt/sources.list.d/docker.list <<< "deb http://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main"

    # Install basic development packages:
    apt-get update
    apt-get install -y docker-engine dnsmasq zsh tmux git-all gnupg-agent

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
    sh -c 'curl --silent --retry 5 --location https://github.com/docker/compose/releases/download/1.8.0/run.sh > /usr/local/bin/docker-compose-1.8.0 && chmod +x /usr/local/bin/docker-compose-1.8.0'
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
      'jyore/flyway:3.2.1',
      'maven:3.3.9-jdk-8',
    ]
  )

  # Bring up internal services specified in docker-compose-vagrant.yml:
  config.vm.provision(
    :docker_compose,
    yml: '/vagrant/docker-compose-vagrant.yml',
    rebuild: true,
    run: 'always',
    executable_install_path: '/usr/local/bin/docker-compose-1.8.0',
    env: {
      COMPOSE_OPTIONS: '-v /vagrant:/vagrant'
    }
  )
end

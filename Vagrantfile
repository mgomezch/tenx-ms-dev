# -*- mode: ruby -*-
# vi: set ft=ruby :

# Set up Vagrant plugins:

plugins=[
  'vagrant-docker-compose',
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
  config.vm.box = 'bento/ubuntu-16.04'

  config.vm.provider 'virtualbox' do |vb|
    vb.cpus = 2
    vb.memory = '1024'
  end



  # Install packages:

  config.vm.provision 'file', source: "files", destination: '.'

  config.vm.provision 'shell', inline: <<-SHELL
    set -e

    rsync -CvzrlptD files/root/ /

    # Set up APT proxy:
  # tee -a /etc/hosts <<< "$(route -n|sed -n -e 's/^0\.0\.0\.0  *\([^ ][^ ]*\) .* eth0/\1/p') host.vagrant.test"
    tee -a /etc/hosts <<< "10.0.2.2 host.vagrant.test" # FIXME: This is VirtualBox-specific, but the above fails

    # Set up Docker APT source:
    apt-get update
    apt-get install -y apt-transport-https ca-certificates software-properties-common
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    tee /etc/apt/sources.list.d/docker.list <<< "deb http://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main"

    # Set up IntelliJ IDEA Community Edition APT source:
    add-apt-repository -y ppa:mmk2410/intellij-idea-community # FIXME: This does not allow for caching, as this package downloads the actual program installation data from the product website

    # Install basic development packages:
    apt-get update
    apt-get install -y dnsmasq zsh tmux tmuxinator git-all vim-gtk iotop nethogs jq p7zip-full p7zip-rar rar unrar gnupg-agent netcat nmap wget curl # intellij-idea-community

    # Install Docker:
    apt-get install -y -o Dpkg::Options::=--force-confold docker-engine

    # Set default user shell:
    chsh -s /bin/zsh vagrant

    # Install Docker-managed Docker Compose shim:
    sh -c 'curl --silent --retry 5 --location https://github.com/docker/compose/releases/download/1.8.0/run.sh > /usr/local/bin/docker-compose-1.8.0 && chmod +x /usr/local/bin/docker-compose-1.8.0'
  SHELL



  # Set up default user environment:

  config.vm.provision 'shell', privileged: false, inline: <<-SHELL
    set -e
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true
    rsync -CvzrlptD files/home/ ~/
    rm -rf files
  SHELL



  # Set up Docker:

  config.vm.provision :docker

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

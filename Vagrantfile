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

  # Set up environment:
  config.vm.provision 'file', source: "files", destination: '.'
  config.vm.provision 'shell', path: 'scripts/setup-internal.sh'
  config.vm.provision 'shell', privileged: false, path: 'scripts/setup-internal-user.sh'
  config.vm.provision 'shell', privileged: false, inline: 'rm -rf files'

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
    yml: '/vagrant/docker-compose-internal.yml',
    rebuild: true,
    run: 'always',
    executable_install_path: '/usr/local/bin/docker-compose-1.8.0',
    env: {
      COMPOSE_OPTIONS: '-v /vagrant:/vagrant'
    }
  )
end

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

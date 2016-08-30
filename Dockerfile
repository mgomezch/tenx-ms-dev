FROM ubuntu:16.04
USER root

# Copy basic files:
COPY files/root/ /

# Configure APT sources:
RUN \
  echo '172.17.0.1 apt-cacher-ng' >> /etc/hosts && \
  echo '172.17.0.1 registry' >> /etc/hosts && \
  sed -i -e 's/^# \(deb.*\)$/\1/' /etc/apt/sources.list && \
  apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    && \
  apt-key adv --keyserver 'hkp://p80.pool.sks-keyservers.net:80' --recv-keys '58118E89F3A912897C070ADBF76221572C52609D' && \
  echo "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main" | tee /etc/apt/sources.list.d/docker.list && \
  true

# Install development tools:
RUN \
  echo '172.17.0.1 apt-cacher-ng' >> /etc/hosts && \
  echo '172.17.0.1 registry' >> /etc/hosts && \
  apt-get update && apt-get install -y \
    curl \
    dnsmasq \
    dnsutils \
    git-all \
    gnupg-agent \
    htop \
    iotop \
    iputils-arping \
    iputils-ping \
    jq \
    maven \
    netcat \
    nethogs \
    net-tools \
    nmap \
    p7zip-full \
    p7zip-rar \
    rar \
    strace \
    tmux \
    tmuxinator \
    unrar \
    vim-gtk \
    wget \
    whois \
    zsh \
    && \
  apt-get install -y -o Dpkg::Options::=--force-confold docker-engine && \
  true

# Install Docker Compose:
RUN curl --silent --location https://github.com/docker/compose/releases/download/1.8.0/run.sh > /usr/local/bin/docker-compose-1.8.0 && chmod +x /usr/local/bin/docker-compose-1.8.0

# Install IntelliJ IDEA Community Edition:
# FIXME: Building a Debian package is very slow; it might be faster to just unpack IntelliJ somewhere and add it to some PATH.
COPY files/ideaIC-*.tar.gz .
RUN \
  echo '172.17.0.1 apt-cacher-ng' >> /etc/hosts && \
  echo '172.17.0.1 registry' >> /etc/hosts && \
  apt-get update && apt-get install -y dpkg-dev fakeroot openjdk-8-jdk && \
  git clone https://github.com/trygvis/intellij-idea-dpkg && \
  (cd intellij-idea-dpkg && \
    tar zxvf ../ideaIC-*.tar.gz && \
    ./build-package -p debian -f IC -v 2.2 -s idea-IC-*/ && \
    dpkg -i repository/debian/intellij-idea-ic-*.deb && \
  true) && \
  rm -rf ideaIC-*.tar.gz intellij-idea-dpkg && \
  apt-get purge -y dpkg-dev fakeroot && \
  apt-get autoremove -y && \
  apt-get clean -y && \
  apt-get autoclean -y && \
  true

# Set up user environment:
WORKDIR /root
RUN sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" || true && chsh -s /bin/zsh
COPY files/home/ /root/
RUN git clone https://github.com/Shougo/dein.vim.git ~/.vim/dein/repos/github.com/Shougo/dein.vim && yes | vim -c ":silent! call dein#install() | :q"

ENTRYPOINT service dnsmasq start && zsh

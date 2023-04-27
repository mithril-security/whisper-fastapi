#!/bin/sh
set -ex

apt-get update -y
apt-get install -y python3.9 python3.9-distutils wget curl git ca-certificates gnupg

# Pip
curl -fsSL https://bootstrap.pypa.io/get-pip.py | python3.9

# GPG stuff for docker
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Docker
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Switch to legacy iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# Download app
cd $HOME
git clone https://github.com/mithril-security/whisper-fastapi.git
cd $HOME/whisper-fastapi
git checkout disable-openchatkit
docker build --target sev-aci -t guest .
cd $HOME

# Install and start model store
python3.9 -m pip install -r model_store_requirements.txt
python3.9 model_store.py download "openai/whisper-tiny.en"

# iptables rules inserted from CLI
iptables -I DOCKER-USER -i docker0 -d 168.63.129.16 -j ACCEPT
iptables -I DOCKER-USER -i docker0 -d 127.0.0.1 -j ACCEPT
iptables -I DOCKER-USER -i docker0 -j DROP

rm -rf /var/lib/apt/lists/* && rm -rf /var/cache/apt/archives/*

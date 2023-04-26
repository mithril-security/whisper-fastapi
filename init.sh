#!/bin/bash
cd /

#Update repositiories
apt-get update

# Install git
apt-get install git -y

# Install docker
apt-get install \
    ca-certificates \
    curl \
    gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Switch to legacy iptables 
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# Start docker service
DOCKER_RAMDISK=true dockerd &
sleep 10

# iptable rules inserted from CLI
iptables -I DOCKER-USER -i docker0 -j DROP

# Download app
cd /
cd whisper-fastapi
docker build -t guest .

# Install and start model store
python3 -m venv env
source env/bin/activate
pip install -r model_store_requirements.txt
python model_store.py download "openai/whisper-tiny.en"
python model_store.py serve --address 0.0.0.0 &

# Build and start enclave app
exec make

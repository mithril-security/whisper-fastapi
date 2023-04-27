#!/bin/sh
set -ex

DOCKER_RAMDISK=true dockerd &
sleep 15

# iptables rules inserted from CLI
iptables -I DOCKER-USER -i docker0 -d 168.63.129.16 -j ACCEPT
iptables -I DOCKER-USER -i docker0 -d 127.0.0.1 -j ACCEPT
#iptables -I DOCKER-USER -i docker0 -j DROP         UNCOMMENT BEFORE PUSH AND WHEN CLI IS READY

cd $HOME/whisper-fastapi
docker build --target sev-aci -t guest .

# Model store
python3.9 model_store.py serve --address 0.0.0.0 &

# Guest
docker run -d -i -t -p 80:80 guest

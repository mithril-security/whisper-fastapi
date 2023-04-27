#!/bin/sh
set -ex

DOCKER_RAMDISK=true dockerd &
sleep 15

cd $HOME/whisper-fastapi
docker build --target sev-aci -t guest .

# Model store
python3.9 model_store.py serve --address 0.0.0.0 &

# Guest
docker run -d -i -t guest

#!/bin/sh

export TEE_ENV=sev-aci

set -x
set -e

python /server.py

# Keep runing if server fails
count=1
while true; do
    printf "[%4d] $HELLO\n" $count
    count=$((count+1))
    sleep 60
done

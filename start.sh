#!/bin/bash

if [ $(id -u) -ne 0 ]; then
    echo "You must run with root privileges."
    exit 1
fi
docker run --rm -d --name pages_frontend -p 8080:8080 -v "$(pwd)"/pages:/usr/src/wardriver pages_frontend && ./driver/scripts/justDrive

#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "You must run with root privileges."
    exit 1
fi
docker run --rm -d --name justdrive-frontend -p 8080:8080 -v "$(pwd)"/www/html:/usr/src/app justdrive-frontend && ./driver/scripts/justDrive

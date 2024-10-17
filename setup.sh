#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "You must run with root privileges."
    exit 1
fi

if docker images | grep -q justdrive; then
    echo "Building docker images for the frontend..."
    docker build -t justdrive-frontend ./ > /dev/null 2>&1 || echo "Error while building the docker image, exiting..." && exit 1
    echo "Docker image has been built"
fi

echo "Marking scripts with appropriate permissions..."
chmod +x ./start
chmod +x ./kill
chmod +x driver/scripts/justDrive
chmod 644 driver/scripts/DriveUtils.pm
echo "Script permissions have been set."

echo "Setting environment variable for network adapter"
printf "\nFind the interface you want to use from the following list...\n"
sleep 4
ip link show
read -pr "Enter the name of your interface (if it doesn't show up, exit this script and run it again once the adapter is properly connected): " interface
SOURCE="export wAdapt=\"$interface\""
case $(basename "$SHELL") in
    bash)
        if [ -f "$HOME/.bashrc" ]; then
            echo "$SOURCE" >> "$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            echo "$SOURCE" >> "$HOME/.bash_profile"
        else
            echo "$SOURCE" >> "$HOME/.profile"
        fi
        ;;
    zsh)
        echo "$SOURCE" >> "$HOME/.zshrc"
        ;;
    fish)
        echo "set -gx wAdapt $interface" >> "$HOME/.config/fish/config.fish"
        ;;
    ksh)
        echo "$SOURCE" >> "$HOME/.kshrc"
        ;;
    *)
        echo "You are using an unsupported shell, you need to manually add your network adapter as an environment variable named 'wAdapt'"
        ;;
esac
echo "Environment variable has been set."

echo "Setting up javascript config file..."
read -pr "Enter your Google Maps API key here: " api_key

cat <<EOL > www/html/js/config.js
const CONFIG = {
    GOOGLE_MAPS_API_KEY: '$api_key'
};
EOL

echo "config.js has been automatically generated with your api_key."

echo "Setting up backend config file..."
cat <<EOL > driver/data/config.cfg
[MODE]=safe
[LOG]=file
EOL
echo "Backend config has been created."

echo "Setup completed."

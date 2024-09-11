#!/bin/bash

echo "Marking scripts with appropriate permissions..."
chmod +x start.sh
chmod +x kill.sh
chmod +x driver/scripts/justDrive
chmod 644 driver/scripts/DriveUtils.pm
echo "Script permissions have been set."

echo "Setting environment variable for network adapter"
ifconfig
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
echo "Setup completed."

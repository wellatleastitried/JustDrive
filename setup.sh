#!/bin/bash

echo "Marking scripts with appropriate permissions..."
chmod +x run.sh
chmod +x kill.sh
chmod +x driver/scripts/justDrive
chmod 644 driver/scripts/DriveUtils.pm
echo "Script permissions have been set."

echo "Setting up javascript config file..."
read -pr "Enter your Google Maps API key here: " api_key

cat <<EOL > www/html/js/config.js
const CONFIG = {
    GOOGLE_MAPS_API_KEY: '$api_key'
};
EOL

echo "config.js has been automatically generated with your api_key."
echo "Setup completed."

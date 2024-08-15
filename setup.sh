#!/bin/bash

echo "Marking runner scripts as executable..."
chmod +x run.sh
chmod +x kill.sh
echo "Scripts have been marked as executable."

echo "Setting up javascript config file..."
read -pr "Enter your Google Maps API key here: " api_key

cat <<EOL > pages/js/config.js
const CONFIG = {
    GOOGLE_MAPS_API_KEY: '$api_key'
};
EOL

echo "config.js has been automatically generated with your api_key."
echo "Setup completed."

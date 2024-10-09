#!/bin/bash
#https://github.com/jxroot/freeuse/
# Setup Banner
cat << "EOF"
###############################################
#                                             #
#       Tor Hidden Service Setup Script       #
#              Powered by Apache              #
#                                             #
###############################################
EOF

# Function to check and install a package if not installed
check_and_install() {
    PACKAGE=$1
    if ! dpkg -l | grep -q "^ii  $PACKAGE"; then
        echo "$PACKAGE is not installed. Installing..."
        sudo apt install -y "$PACKAGE"
    else
        echo "$PACKAGE is already installed."
    fi
}

# Function to check if the hidden service already exists
check_hidden_service() {
    HOSTNAME_FILE="/var/lib/tor/hidden_service/hostname"
    if [ -f "$HOSTNAME_FILE" ]; then
        echo "A hidden service already exists at $(cat $HOSTNAME_FILE)."
        echo "Exiting script to avoid overwriting existing hidden service."
        exit 1
    fi
}

# Update package list
echo "Updating package list..."
sudo apt update

# Check and install required packages
check_and_install apache2
check_and_install ufw
check_and_install tor

# Enable necessary Apache modules
echo "Enabling Apache modules..."
sudo a2enmod rewrite

# Check if a hidden service exists and handle accordingly
check_hidden_service

# Remove default index.html in /var/www/html/
if [ -f "/var/www/html/index.html" ]; then
    echo "Removing default Apache index.html..."
    sudo rm /var/www/html/index.html
fi

# Configure Tor for a hidden service
echo "Configuring Tor..."
sudo bash -c 'echo -e "\nHiddenServiceDir /var/lib/tor/hidden_service/\nHiddenServicePort 80 127.0.0.1:80" >> /etc/tor/torrc'

# Create web directory
echo "Creating web directory..."
sudo mkdir -p /var/www/html/tor

# Set correct permissions for the web directory
sudo chown -R www-data:www-data /var/www/html/tor
sudo chmod -R 755 /var/www/html/tor

# Add the HTML banner content
sudo bash -c 'cat > /var/www/html/tor/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Tor Hidden Service</title>
    <style>
        body {
            background-color: #1b1b1b;
            color: #ffffff;
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            text-align: center;
        }
        .banner {
            background: linear-gradient(135deg, #5a3ea3, #ee6352);
            border-radius: 15px;
            padding: 50px;
            box-shadow: 0px 10px 20px rgba(0, 0, 0, 0.3);
            max-width: 600px;
        }
        h1 {
            font-size: 3em;
            margin: 0;
            color: #ffffff;
        }
        p {
            font-size: 1.2em;
            color: #ffffff;
        }
        .highlight {
            color: #ee6352;
            font-weight: bold;
        }
        footer {
            margin-top: 20px;
            font-size: 0.9em;
            color: #ccc;
        }
    </style>
</head>
<body>
    <div class="banner">
        <h1>Welcome to the <span class="highlight">Tor Hidden Service</span></h1>
        <p>Your secure gateway to the dark web</p>
        <footer>Powered by Apache & Tor</footer>
    </div>
</body>
</html>
EOF'

# Configure Apache for the hidden service
echo "Configuring Apache..."
sudo bash -c 'cat > /etc/apache2/sites-available/tor.conf <<EOF
<VirtualHost *:80>
    DocumentRoot /var/www/html/tor
    <Directory /var/www/html/tor>
        AllowOverride None
        Require ip 127.0.0.1
    </Directory>
</VirtualHost>
EOF'

# Enable the site configuration
sudo a2ensite tor

# Configure UFW
echo "Configuring firewall (UFW)..."
sudo ufw allow ssh
sudo ufw allow from 127.0.0.1 to any port 80
sudo ufw default deny incoming
sudo ufw enable

# Restart services
echo "Restarting Tor and Apache..."
sudo systemctl restart tor
sudo systemctl restart apache2

# Get the .onion hostname
ONION_HOSTNAME=$(sudo cat /var/lib/tor/hidden_service/hostname)

# Output the .onion address
if [ -n "$ONION_HOSTNAME" ]; then
    echo "Your Tor hidden service is set up. Access it at: $ONION_HOSTNAME"
else
    echo "Error: Could not retrieve the .onion address."
fi

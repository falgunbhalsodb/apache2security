#!/bin/bash

# Install and configure mod_evasive for Apache2
# Use: sudo bash install_mod_evasive.sh

echo "Updating package list..."
apt-get update

echo "Installing mod_evasive..."
apt-get install -y libapache2-mod-evasive

echo "Creating mod_evasive log directory..."
mkdir -p /var/log/mod_evasive
chown -R www-data:www-data /var/log/mod_evasive
chmod 700 /var/log/mod_evasive

echo "Configuring mod_evasive settings..."

# Create evasive config file
cat <<EOT > /etc/apache2/mods-available/evasive.conf
<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        2
    DOSSiteCount        50
    DOSPageInterval     1
    DOSSiteInterval     1
    DOSBlockingPeriod   86400

    DOSLogDir           "/var/log/mod_evasive"
    DOSEmailNotify      falgun@yellowpanther.co.uk
    DOSSystemCommand    "iptables -I INPUT -s %s -j DROP"
    DOSWhitelist        127.0.0.1
    DOSWhitelist        122.173.87.214
    DOSWhitelist        106.201.234.176
</IfModule>
EOT

echo "Enabling mod_evasive module..."
a2enmod evasive

echo "Reloading Apache2 service..."
systemctl reload apache2

echo "mod_evasive installed and configured successfully!"

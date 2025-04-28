#!/bin/bash

# Secure Apache2 Configuration Script (Advanced)
# Run as root (sudo ./secure_apache.sh)

APACHE_CONF="/etc/apache2/apache2.conf"
SECURITY_CONF="/etc/apache2/conf-available/security.conf"

echo "Securing Apache2 configuration..."

# Backup important files
echo "Creating backup of configuration files..."
cp $APACHE_CONF ${APACHE_CONF}.bak
cp $SECURITY_CONF ${SECURITY_CONF}.bak

# 1. Hide Apache version info
echo "Hardening ServerTokens and ServerSignature..."
sed -i 's/^ServerTokens .*/ServerTokens Prod/' $SECURITY_CONF
sed -i 's/^ServerSignature .*/ServerSignature Off/' $SECURITY_CONF

# 2. Disable directory listing
echo "Disabling directory listing..."
sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/' $APACHE_CONF

# 3. Add security headers
echo "Adding basic security headers..."
cat <<EOT > /etc/apache2/conf-available/security-headers.conf
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "no-referrer-when-downgrade"
    Header always set Permissions-Policy "geolocation=(), microphone=()"
</IfModule>
EOT
a2enconf security-headers

# 4. Basic DoS protections
echo "Applying basic DoS protections..."
cat <<EOT >> $APACHE_CONF

# Custom security settings
Timeout 60
MaxRequestWorkers 150
KeepAlive On
KeepAliveTimeout 5
LimitRequestBody 10485760
EOT

# 5. Restrict access to sensitive files
echo "Restricting access to sensitive files..."
cat <<EOT > /etc/apache2/conf-available/restrict-files.conf
<FilesMatch "(^\.ht|\.git|\.env|composer\.(json|lock))">
    Require all denied
</FilesMatch>
EOT
a2enconf restrict-files

# 6. Install and configure mod_evasive
echo "Installing mod_evasive for blocking bots..."
apt-get update
apt-get install -y libapache2-mod-evasive

mkdir -p /var/log/mod_evasive

cat <<EOT > /etc/apache2/mods-available/evasive.conf
<IfModule mod_evasive20.c>
    DOSHashTableSize    3097
    DOSPageCount        2
    DOSSiteCount        50
    DOSPageInterval     1
    DOSSiteInterval     1
    DOSBlockingPeriod   86400
    DOSEmailNotify      you@example.com
    DOSLogDir           "/var/log/mod_evasive"
    ###YPOFFICEA
    DOSWhitelist        122.173.87.214
    ###VARIS OFFICE
    DOSWhitelist        106.201.234.176
</IfModule>
EOT

a2enmod evasive

# 7. Auto block IPs with fail2ban (optional but recommended)
#echo "Installing and configuring fail2ban for better IP banning..."
#apt-get install -y fail2ban
#
#cat <<EOT > /etc/fail2ban/jail.d/apache-dos.conf
#[apache-dos]
#enabled = true
#port    = http,https
#filter  = apache-dos
#logpath = /var/log/apache2/access.log
#maxretry = 10
#findtime = 60
#bantime = 86400
#EOT

#cat <<EOT > /etc/fail2ban/filter.d/apache-dos.conf
#[Definition]
#failregex = <HOST>.*"(GET|POST).*
#ignoreregex =
#EOT

#systemctl restart fail2ban

# 8. Disable script execution globally (only allow manually if needed)
echo "Blocking all script execution globally..."
cat <<EOT > /etc/apache2/conf-available/disable-scripts.conf
<Directory /var/www/>
    Options -ExecCGI
    AllowOverride None
    Require all granted
</Directory>

<FilesMatch "\.(pl|py|cgi|sh|rb)$">
    Require all denied
</FilesMatch>
EOT
a2enconf disable-scripts

# 9. Reload Apache
echo "Restarting Apache2 service..."
systemctl reload apache2

echo "Apache2 has been hardened and secured!"

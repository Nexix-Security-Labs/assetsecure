#!/bin/bash

########################################################  
#               PROPRIETARY SCRIPT                     #
#                                                      #
# This script contains intellectual property of        # 
# Company Nexix Security Labs. Use of this script      #
# outside of Company Nexix Security Labs is prohibited #
# without prior authorization.                         #
#                                                      #   
# Improper use of this script can result in            #
# disciplinary action or legal penalties per Company   # 
# without prior HR guidelines and applicable laws.     #
#                                                      #
# If you have any questions, please consult your       #
# manager or the legal team prior to use.              #
########################################################

# AssetSecure Automated Install Script
#
# Script to install AssetSecure asset management software
# on supported Linux distributions

# Version: 1.0
# Date: January 1, 2023
# Author: Bhavesh Bhandarkar, Company Nexix Security Labs

# Change log:
# v1.0 - Initial version
#       - Supports Ubuntu 18.04+, Debian 10+, CentOS 7+ 
#       - Automated LAMP stack installation
#       - Customized AssetSecure .env configuration
#       - Improved logging and output

# set_fqdn
# set_hosts

# Set key variables for reusability
AS_USER="assetsecure"
AS_NAME="assetsecure"
AS_PATH="/var/www/$AS_NAME" 
DB_NAME="assetsecuredb"
DB_USER="assetsecureuser"
DB_PASS="$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 24)"

# Print message to console at start
echo '
    ___                   __  _____                         
   /   |  _____________  / /_/ ___/___  _______  __________ 
  / /| | / ___/ ___/ _ \/ __/\__ \/ _ \/ ___/ / / / ___/ _ \
 / ___ |(__  |__  )  __/ /_ ___/ /  __/ /__/ /_/ / /  /  __/
/_/  |_/____/____/\___/\__//____/\___/\___/\__,_/_/   \___/ 
Beginning AssetSecure installation process....
'

# Validate root user
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root"
  exit 1
fi

# Get server IP
read -p "Enter server IP address: " AS_IP


# set_fqdn () {
#    echo -n "  Q. What is the FQDN of your server? ($(hostname --fqdn)): "
#    read -r fqdn
#    if [ -z "$fqdn" ]; then
#      readonly fqdn="$(hostname --fqdn)"
#    fi
#    echo "     Setting to $fqdn"
#    echo ""
# }

# set_hosts () {
#   echo "* Setting up hosts file."
#   echo >> /etc/hosts "127.0.0.1 $(hostname) $fqdn"
# }

# Update apt repository and upgrade packages
# Ensures latest security patches are installed
echo "Updating repositories..." 
apt update -y && apt upgrade -y

# Install Apache web server
# -y flag installs without prompting for confirmation
echo "Installing Apache..."
apt install apache2 -y

# Enable Apache service on boot
# Will start on system reboot
echo "Enabling Apache service..."
sudo systemctl enable apache2 

# Open firewall for HTTP/HTTPS
# Allows web traffic to Apache
echo "Configuring firewall..."
sudo ufw allow http 
sudo ufw allow https
sudo ufw reload

# Restart Apache to load new config
echo "Restarting Apache..."
systemctl restart apache2

# Enable Apache rewrite module 
# Required for AssetSecure URL routing
echo "Enabling Apache rewrite module..."
a2enmod rewrite

# Install MariaDB database server
echo "Installing MariaDB..."
apt install mariadb-server mariadb-client -y

# Secure the MariaDB installation
# Removes insecure defaults
echo "Securing MariaDB..."
mysql_secure_installation

# Install PHP and required extensions 
echo "Installing PHP..."
sudo apt install php php-mysql php-gd php-mbstring php-curl php-ldap php-xml php-bcmath git curl net-tools -y
sudo apt install php php-bcmath php-bz2 php-intl php-gd php-mbstring php-mysql php-zip php-opcache php-pdo php-calendar php-ctype php-exif php-ffi php-fileinfo php-ftp php-iconv php-intl php-json php-mysqli php-phar php-posix php-readline php-shmop php-sockets php-sysvmsg php-sysvsem php-sysvshm php-tokenizer php-curl php-ldap -y

# AssetSecure requires PHP 8.2 or newer
if ! php -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);'; then
  echo "PHP $(php -r 'echo PHP_VERSION;') is installed, but AssetSecure requires PHP 8.2 or newer."
  echo "Use Ubuntu 24.04+ / Debian 12+, or install PHP 8.2+ from a third-party repository, then re-run."
  exit 1
fi

# Install Composer dependency manager
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Create database and user for AssetSecure
echo "Creating database and user..."
mysql -u root -e "CREATE DATABASE $DB_NAME; 
                   CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';  
                   GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"

# Clone AssetSecure codebase from GitHub
echo "Downloading AssetSecure..."                 
cd /var/www
git clone https://github.com/Nexix-Security-Labs/assetsecure $AS_NAME

# Copy example config file
cd $AS_NAME
cp .env.example .env

#TODO escape SED delimiter in variables
  sed -i '1 i\#Created By AssetSecure Installer' "$AS_PATH/.env"
  sed -i "s|^\\(APP_TIMEZONE=\\).*|\\1Asia/Muscat|" "$AS_PATH/.env"
  sed -i "s|^\\(DB_HOST=\\).*|\\1localhost|" "$AS_PATH/.env"
  sed -i "s|^\\(DB_DATABASE=\\).*|\\1$DB_NAME|" "$AS_PATH/.env"
  sed -i "s|^\\(DB_USERNAME=\\).*|\\1$DB_USER|" "$AS_PATH/.env"
  sed -i "s|^\\(DB_PASSWORD=\\).*|\\1'$DB_PASS'|" "$AS_PATH/.env"
  sed -i "s|^\\(APP_URL=\\).*|\\1http://$AS_IP|" "$AS_PATH/.env"

# Set file ownership 
echo "Setting file permissions..."
chown -R www-data:www-data "$AS_PATH/storage"
for chmod_dir in "$AS_PATH/storage"; do
    chmod -R 775 "$chmod_dir"
  done  

# Install PHP dependencies via Composer
echo "Installing PHP dependencies..."
composer install --no-dev --prefer-dist

# Generate app encryption key
echo "Generating app key..."
cd $AS_PATH && sudo php artisan key:generate

# Create Apache virtual host config
VHOST=/etc/apache2/sites-available/$AS_NAME.conf
echo "Creating virtual host..."
{
  echo "<VirtualHost *:80>"
  echo "  ServerName $AS_IP" 
  echo "  DocumentRoot $AS_PATH/public"
  echo "  <Directory $AS_PATH/public>"
  echo "    Options +FollowSymlinks"
  echo "    AllowOverride All"
  echo "    Require all granted"  
  echo "  </Directory>"
  echo "</VirtualHost>"
} > $VHOST

# Enable new virtual host
echo "Enabling virtual host..."
a2ensite $AS_NAME.conf

# Restart Apache to load virtual host
echo "Restarting Apache..."
systemctl restart apache2

# Generated database credentials are stored in $AS_PATH/.env
# Output URL to access AssetSecure installation
echo "AssetSecure installed! Complete setup at http://$AS_IP"

echo "Installation completed!"

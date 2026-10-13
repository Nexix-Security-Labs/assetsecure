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

# Version: 1.2
# Date: October 13, 2026
# Author: Bhavesh Bhandarkar, Company Nexix Security Labs

# Change log:
# v1.0 - Initial version
#       - Supports Ubuntu 18.04+, Debian 10+, CentOS 7+ 
#       - Automated LAMP stack installation
#       - Customized AssetSecure .env configuration
#       - Improved logging and output
# v1.1 - AssetSecure 8.x (Laravel 12, PHP 8.2+)
#       - Install a chosen branch/tag (AS_BRANCH), default master
#       - Safe to re-run: reuses existing database, user, .env and APP_KEY
#       - Stops on errors instead of reporting a broken install as done
#       - Runs database migrations, sets up the scheduler cron job
#       - Installs libapache2-mod-php, disables the default Apache site
#       - Skips the firewall step when ufw is not installed
# v1.2 - Dedicated "assetsecure" user owns the code; the web server can only
#         write storage/, bootstrap/cache and public/uploads
#       - Composer runs as that user, artisan commands as the web server user
#       - Address prompt defaults to localhost on WSL2 (else the server's IP);
#         APP_URL must match the address used in the browser
#       - Works without systemd (WSL2 without systemd, containers)

# set_fqdn
# set_hosts

# Set key variables for reusability
AS_USER="assetsecure"
AS_NAME="assetsecure"
AS_PATH="/var/www/$AS_NAME"
AS_REPO="${AS_REPO:-https://github.com/Nexix-Security-Labs/assetsecure}"
AS_BRANCH="${AS_BRANCH:-master}"
DB_NAME="assetsecuredb"
DB_USER="assetsecureuser"
DB_PASS=""
WEB_USER="www-data"
AS_HOME="/home/$AS_USER"

export DEBIAN_FRONTEND=noninteractive

# Stop with a clear message when a required step fails
fail () {
  echo ""
  echo "ERROR: $1"
  echo "Installation stopped. Fix the problem above and re-run this script; it is safe to run again."
  exit 1
}

# True when running under systemd (WSL2 can run without it)
has_systemd () {
  [ -d /run/systemd/system ]
}

# Manage a service with systemd when available, otherwise with "service"
# Usage: svc enable|enable-now|restart <service>
svc () {
  if has_systemd; then
    case "$1" in
      enable-now) systemctl enable --now "$2" ;;
      *) systemctl "$1" "$2" ;;
    esac
  else
    case "$1" in
      enable) return 0 ;;
      enable-now) service "$2" start ;;
      *) service "$2" "$1" ;;
    esac
  fi
}

# Run a command as the application owner / as the web server user
as_app () {
  runuser -u "$AS_USER" -- env HOME="$AS_HOME" "$@"
}
as_web () {
  runuser -u "$WEB_USER" -- "$@"
}

# Code is owned by the application user; only the directories AssetSecure
# writes to at runtime are owned by (and writable for) the web server.
set_permissions () {
  chown -R "$AS_USER":"$WEB_USER" "$AS_PATH"
  for writable_dir in "$AS_PATH/storage" "$AS_PATH/bootstrap/cache" "$AS_PATH/public/uploads"; do
    mkdir -p "$writable_dir"
    chown -R "$WEB_USER":"$WEB_USER" "$writable_dir"
    # Directories 2770 (new files keep the web server group), files 660: logs,
    # sessions, private uploads and OAuth keys are not readable by other users
    chmod -R u=rwX,g=rwX,o= "$writable_dir"
    find "$writable_dir" -type d -exec chmod g+s {} +
  done
  if [ -f "$AS_PATH/.env" ]; then
    chown "$AS_USER":"$WEB_USER" "$AS_PATH/.env"
    chmod 640 "$AS_PATH/.env"
  fi
}

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

# Ask for the address users will type in the browser. It becomes APP_URL, and
# AssetSecure builds every link, script and stylesheet URL from it, so it must
# match the browser address exactly (otherwise pages load without styling).
IS_WSL=0
if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
  IS_WSL=1
  DEFAULT_ADDR="localhost"   # WSL2 forwards "localhost" to Windows; 127.0.0.1 may not work
else
  DEFAULT_ADDR="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [ -n "$DEFAULT_ADDR" ] || DEFAULT_ADDR="localhost"
fi
read -r -p "Enter the address you will open in your browser (IP or hostname) [$DEFAULT_ADDR]: " AS_IP
AS_IP="$(echo "$AS_IP" | tr -d '[:space:]')"
[ -n "$AS_IP" ] || AS_IP="$DEFAULT_ADDR"
AS_IP="${AS_IP#http://}"
AS_IP="${AS_IP#https://}"
AS_IP="${AS_IP%%/*}"
[ -n "$AS_IP" ] || fail "A server address is required."
echo "Using http://$AS_IP as the AssetSecure URL."

echo "Installing AssetSecure from $AS_REPO (branch/tag: $AS_BRANCH)"

# Update apt package lists. Upgrading the whole system is left to the
# administrator: a full upgrade can stop on unrelated packages (for example
# held or pinned browser packages) and is not needed for AssetSecure.
echo "Updating repositories..."
apt-get update -y || fail "apt-get update failed."

# Install Apache web server with the PHP module
echo "Installing Apache..."
apt-get install -y apache2 libapache2-mod-php || fail "Could not install Apache."

# Enable Apache service on boot
echo "Enabling Apache service..."
svc enable apache2

# Open firewall for HTTP/HTTPS if ufw is in use
echo "Configuring firewall..."
if command -v ufw >/dev/null 2>&1; then
  ufw allow http
  ufw allow https
  ufw reload
else
  echo "ufw is not installed, skipping firewall configuration."
fi

# Enable Apache rewrite module
# Required for AssetSecure URL routing
echo "Enabling Apache rewrite module..."
a2enmod rewrite

# Install MariaDB database server
echo "Installing MariaDB..."
apt-get install -y mariadb-server mariadb-client || fail "Could not install MariaDB."
svc enable-now mariadb || fail "Could not start MariaDB."

# Secure the MariaDB installation
# Removes insecure defaults
echo "Securing MariaDB..."
mysql_secure_installation

# Install PHP and required extensions
echo "Installing PHP..."
apt-get install -y php php-cli php-mysql php-gd php-mbstring php-curl php-ldap php-xml php-bcmath \
  php-bz2 php-intl php-zip php-opcache php-readline php-tokenizer \
  git curl unzip cron net-tools openssl || fail "Could not install PHP and its extensions."
svc enable-now cron || echo "WARNING: could not start cron; scheduled tasks will not run until it is started."

# AssetSecure requires PHP 8.2 or newer
if ! php -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);'; then
  echo "PHP $(php -r 'echo PHP_VERSION;') is installed, but AssetSecure requires PHP 8.2 or newer."
  echo "Use Ubuntu 24.04+ / Debian 12+, or install PHP 8.2+ from a third-party repository, then re-run."
  exit 1
fi

# Install Composer dependency manager
echo "Installing Composer..."
COMPOSER_TMP="$(mktemp -d)"
curl -sS -o "$COMPOSER_TMP/composer-setup.php" https://getcomposer.org/installer || fail "Could not download Composer."
php "$COMPOSER_TMP/composer-setup.php" --quiet --install-dir=/usr/local/bin --filename=composer || fail "Could not install Composer."
rm -rf "$COMPOSER_TMP"

# Create the application user that owns the code (not root, not the web server)
if ! id "$AS_USER" >/dev/null 2>&1; then
  echo "Creating application user $AS_USER..."
  useradd --system --create-home --home-dir "$AS_HOME" --shell /usr/sbin/nologin "$AS_USER" \
    || fail "Could not create user $AS_USER."
fi
usermod -a -G "$WEB_USER" "$AS_USER" || fail "Could not add $AS_USER to the $WEB_USER group."
mkdir -p "$AS_HOME" && chown "$AS_USER":"$AS_USER" "$AS_HOME"

# Download or update the AssetSecure codebase (as the application user)
echo "Downloading AssetSecure..."
if [ -d "$AS_PATH/.git" ]; then
  echo "$AS_PATH already exists, updating it to $AS_BRANCH..."
  # Earlier installs were owned by root; hand the checkout to the application user
  chown -R "$AS_USER":"$WEB_USER" "$AS_PATH"
  # Permission changes made by this installer (chmod on storage etc.) are not code changes
  as_app git -C "$AS_PATH" config core.fileMode false
  as_app git -C "$AS_PATH" fetch origin "$AS_BRANCH" || fail "Could not fetch $AS_BRANCH from $AS_REPO."
  as_app git -C "$AS_PATH" checkout -B "$AS_BRANCH" FETCH_HEAD \
    || fail "Could not check out $AS_BRANCH: files in $AS_PATH were modified. Review them with: git -C $AS_PATH status"
elif [ -e "$AS_PATH" ] && [ -n "$(ls -A "$AS_PATH" 2>/dev/null)" ]; then
  fail "$AS_PATH exists but is not a git checkout. Move it away and re-run."
else
  mkdir -p "$AS_PATH"
  chown "$AS_USER":"$WEB_USER" "$AS_PATH"
  as_app git clone --branch "$AS_BRANCH" "$AS_REPO" "$AS_PATH" || fail "Could not clone $AS_REPO ($AS_BRANCH)."
  as_app git -C "$AS_PATH" config core.fileMode false
fi
cd "$AS_PATH" || fail "Could not enter $AS_PATH."

# Create or reuse the .env configuration. On a re-run the existing database
# password and APP_KEY are kept, so the install and its encrypted data stay valid.
if [ -f "$AS_PATH/.env" ]; then
  echo "Keeping existing $AS_PATH/.env"
  DB_PASS="$(grep -E '^DB_PASSWORD=' "$AS_PATH/.env" | head -n1 | cut -d= -f2- | tr -d "'\"")"
else
  cp .env.example .env
  sed -i '1 i\#Created By AssetSecure Installer' "$AS_PATH/.env"
fi
if [ -z "$DB_PASS" ]; then
  DB_PASS="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)"
fi

sed -i "s|^\\(APP_TIMEZONE=\\).*|\\1Asia/Muscat|" "$AS_PATH/.env"
sed -i "s|^\\(DB_HOST=\\).*|\\1localhost|" "$AS_PATH/.env"
sed -i "s|^\\(DB_DATABASE=\\).*|\\1$DB_NAME|" "$AS_PATH/.env"
sed -i "s|^\\(DB_USERNAME=\\).*|\\1$DB_USER|" "$AS_PATH/.env"
sed -i "s|^\\(DB_PASSWORD=\\).*|\\1'$DB_PASS'|" "$AS_PATH/.env"
sed -i "s|^\\(APP_URL=\\).*|\\1http://$AS_IP|" "$AS_PATH/.env"

# Create the database and user, or bring an existing user in line with .env
echo "Creating database and user..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
                  CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
                  ALTER USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
                  GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';
                  FLUSH PRIVILEGES;" || fail "Could not create the database or database user."

# Generate the app encryption key only if there is none yet (same format as
# "php artisan key:generate"). Never rotate an existing key: encrypted custom
# fields depend on it.
if grep -qE '^APP_KEY=base64:.+' "$AS_PATH/.env"; then
  echo "Keeping existing app key."
else
  echo "Generating app key..."
  APP_KEY_VALUE="base64:$(openssl rand -base64 32)"
  if grep -qE '^APP_KEY=' "$AS_PATH/.env"; then
    sed -i "s|^APP_KEY=.*|APP_KEY=$APP_KEY_VALUE|" "$AS_PATH/.env"
  else
    echo "APP_KEY=$APP_KEY_VALUE" >> "$AS_PATH/.env"
  fi
  grep -qE '^APP_KEY=base64:.+' "$AS_PATH/.env" || fail "Could not write the app key to .env."
fi

# Set file ownership and permissions
echo "Setting file permissions..."
set_permissions

# Install PHP dependencies via Composer (as the application user, not root)
echo "Installing PHP dependencies..."
as_app /usr/local/bin/composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader --working-dir="$AS_PATH" \
  || fail "composer install failed. Check that $AS_BRANCH is an AssetSecure 8.x branch."
[ -f "$AS_PATH/vendor/autoload.php" ] || fail "Composer did not create vendor/autoload.php."
set_permissions

# Create or update the database tables (as the web server user, so every file
# written under storage/ stays writable for the web server)
echo "Running database migrations..."
as_web php artisan migrate --force || fail "Database migrations failed."
as_web php artisan config:clear
as_web php artisan cache:clear

# Run the Laravel scheduler every minute (alerts, reminders, cleanups)
echo "Setting up the scheduler..."
echo "* * * * * $WEB_USER /usr/bin/php $AS_PATH/artisan schedule:run >> /dev/null 2>&1" > /etc/cron.d/$AS_NAME
chmod 644 /etc/cron.d/$AS_NAME

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
  echo "  ErrorLog \${APACHE_LOG_DIR}/$AS_NAME-error.log"
  echo "  CustomLog \${APACHE_LOG_DIR}/$AS_NAME-access.log combined"
  echo "</VirtualHost>"
} > "$VHOST"

# Enable the AssetSecure site and disable Apache's default page
echo "Enabling virtual host..."
a2ensite $AS_NAME.conf
a2dissite 000-default.conf >/dev/null 2>&1 || true
apache2ctl configtest || fail "Apache configuration test failed."

# Restart Apache to load virtual host
echo "Restarting Apache..."
svc restart apache2 || fail "Apache did not start. Check: systemctl status apache2 (or: service apache2 status)"

# Confirm the site answers before reporting success
if curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1/" -H "Host: $AS_IP" | grep -qE '^(200|302)$'; then
  echo "AssetSecure is responding on port 80."
else
  echo "WARNING: AssetSecure is not answering on http://127.0.0.1/ yet."
  echo "Check: systemctl status apache2 ; ss -ltnp | grep ':80' ; tail -n 50 /var/log/apache2/$AS_NAME-error.log ; tail -n 50 $AS_PATH/storage/logs/laravel.log"
fi

# Generated database credentials are stored in $AS_PATH/.env
# Output URL to access AssetSecure installation
echo "AssetSecure installed! Complete setup at http://$AS_IP/setup"
echo "Open exactly this address in the browser. To change it later, edit APP_URL in"
echo "$AS_PATH/.env, then run: sudo -u $WEB_USER php $AS_PATH/artisan config:clear"
if [ "$IS_WSL" = "1" ]; then
  echo ""
  echo "WSL2: open http://$AS_IP/setup in your Windows browser."
  if ! has_systemd; then
    echo "systemd is not enabled in this WSL distribution, so services do not start"
    echo "automatically. After each WSL restart run:"
    echo "  sudo service mariadb start && sudo service apache2 start && sudo service cron start"
  fi
fi

echo "Installation completed!"

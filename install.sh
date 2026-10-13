#!/bin/bash
# ensure running as root
if [ "$(id -u)" != "0" ]; then
    #Debian doesnt have sudo if root has a password.
    if ! hash sudo 2>/dev/null; then
        exec su -c "$0" "$@"
    else
        exec sudo "$0" "$@"
    fi
fi

# -O overwrites an older assetsecure.sh instead of saving the download as assetsecure.sh.1
wget -q -O assetsecure.sh https://raw.githubusercontent.com/Nexix-Security-Labs/assetsecure/master/assetsecure.sh \
  || { echo "Could not download assetsecure.sh"; exit 1; }
chmod 744 assetsecure.sh
./assetsecure.sh 2>&1 | tee -a /var/log/assetsecure-install.log

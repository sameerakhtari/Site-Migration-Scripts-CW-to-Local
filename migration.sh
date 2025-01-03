#!/bin/bash

# Print the starting message
echo "Site Migration Script"

# Function to verify and remove packages if installed
verify_and_remove() {
    local package_name=$1
    if dpkg -l | grep -q "$package_name"; then
        echo "$package_name is installed. Removing..."
        sudo apt-get remove --purge -y "$package_name"
    else
        echo "$package_name is not installed."
    fi
}

# Verify and remove required packages
verify_and_remove "php"
sudo ./install_php_fpm.sh

verify_and_remove "apache2"
sudo ./install_apache.sh

verify_and_remove "varnish"
sudo ./install_varnish.sh

verify_and_remove "nginx"
sudo ./install_nginx.sh

verify_and_remove "certbot"
sudo ./install_certbot_ssl.sh

# Execute migration scripts
echo "Running migration scripts..."
sudo ./cloudways_backup.sh
sudo ./fetch_backup.sh
sudo ./extract_move_backup.sh
sudo ./database.sh
sudo ./enable-module.sh
sudo ./varnish-failover.sh

# Print completion message
echo "Migration Completed"

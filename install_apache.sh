#!/bin/bash

# Function to install Apache and update configurations
install_and_update_apache() {
  echo "Installing Apache..."
  sudo apt update
  sudo apt install -y apache2

  echo "Starting Apache service..."
  sudo systemctl start apache2

  echo "Enabling Apache to start on boot..."
  sudo systemctl enable apache2

  echo "Updating /etc/apache2/apache2.conf..."
  sudo sed -i '/<Directory \/var\/www\//,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

  echo "Updating /etc/apache2/ports.conf to use port 8080..."
  # Replace 'Listen 80' with 'Listen 8080'
  sudo sed -i 's/^Listen 80$/Listen 8080/' /etc/apache2/ports.conf

  echo "Updating /etc/apache2/sites-available/000-default.conf..."

  # 1. Extract PHP-FPM socket path from details-file
  PHP_FPM_SOCKET=$(grep "^php_fpm_socket:" ./details-file | cut -d ' ' -f 2)
  
  # 2. Parse just the numeric version from that path (e.g., 8.3)
  PHP_FPM_VERSION=$(echo "$PHP_FPM_SOCKET" | grep -oP '\d+\.\d+')

  if [ -z "$PHP_FPM_VERSION" ]; then
    echo "PHP-FPM version not found in details-file. Please ensure it exists."
    exit 1
  fi

  # 3. Change VirtualHost from 80 to 8080
  sudo sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:8080>/' /etc/apache2/sites-available/000-default.conf

  # 4. Change DocumentRoot to /var/www/html/public_html
  sudo sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html/public_html|' /etc/apache2/sites-available/000-default.conf

  # 5. Ensure 'index.php' is in DirectoryIndex
  if ! grep -q "index.php" /etc/apache2/sites-available/000-default.conf; then
    sudo sed -i '/DirectoryIndex/s/index.html/index.php index.html/' /etc/apache2/sites-available/000-default.conf
  fi

  # 6. Check if we already have a "SetHandler \"proxy:unix:" line
  if grep -q 'SetHandler "proxy:unix:' /etc/apache2/sites-available/000-default.conf; then
    # -- The block exists, so just update the existing line(s) --
    echo "Updating existing SetHandler lines for PHP-FPM..."
    sudo sed -i "s|SetHandler \"proxy:unix:.*|SetHandler \"proxy:unix:${PHP_FPM_SOCKET}|fcgi://localhost/\"|" /etc/apache2/sites-available/000-default.conf
  else
    # -- The block does NOT exist, so insert a new <FilesMatch> block --
    echo "Inserting new <FilesMatch> block for PHP-FPM..."
    sudo sed -i "/DocumentRoot \\/var\\/www\\/html\\/public_html/a \\
    <FilesMatch \\.php\$>\\n        SetHandler \"proxy:unix:${PHP_FPM_SOCKET}|fcgi://localhost/\"\\n    </FilesMatch>" /etc/apache2/sites-available/000-default.conf
  fi

  echo "Restarting Apache to apply changes..."
  sudo systemctl restart apache2

  echo "Apache installation and configuration completed."
}

# Execute the function
install_and_update_apache

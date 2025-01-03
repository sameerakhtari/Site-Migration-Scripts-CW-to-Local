#!/bin/bash

# Function to install PHP-FPM
install_php_fpm() {
  echo "Installing PHP-FPM..."
  sudo apt update
  sudo apt install -y php-fpm

  # Determine the latest PHP version installed
  PHP_VERSION=$(ls /etc/php | sort -V | tail -n 1)

  if [ -z "$PHP_VERSION" ]; then
    echo "No PHP versions found in /etc/php. Please verify the installation."
    exit 1
  fi

  echo "Latest PHP version detected: $PHP_VERSION"

  # Check the PHP-FPM socket path
  PHP_FPM_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

  if [ ! -S "$PHP_FPM_SOCKET" ]; then
    echo "PHP-FPM socket not found at $PHP_FPM_SOCKET. Please verify the installation."
    exit 1
  fi

  echo "PHP-FPM socket found: $PHP_FPM_SOCKET"

  # Add or update the socket in the details-file
  DETAILS_FILE="./details-file"

  if [ -f "$DETAILS_FILE" ]; then
    # Update the PHP-FPM socket if the file exists
    if grep -q "^php_fpm_socket:" "$DETAILS_FILE"; then
      sed -i "s|^php_fpm_socket:.*|php_fpm_socket: $PHP_FPM_SOCKET|" "$DETAILS_FILE"
    else
      echo "php_fpm_socket: $PHP_FPM_SOCKET" >> "$DETAILS_FILE"
    fi
  else
    # Create the details-file and add the PHP-FPM socket
    echo "details-file not found. Creating a new one..."
    cat > "$DETAILS_FILE" <<EOL
# Paths and Other Settings
php_fpm_socket: $PHP_FPM_SOCKET
EOL
  fi

  echo "PHP-FPM installation and configuration completed."
}

# Execute the installation
install_php_fpm

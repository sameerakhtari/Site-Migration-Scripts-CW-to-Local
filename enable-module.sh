#!/bin/bash

# Function to enable Apache modules and restart services
enable_modules_and_restart() {
  # Load PHP version from details-file
  PHP_VERSION=$(grep "^php_fpm_socket:" ./details-file | sed -E 's|.*/php([0-9.]+)-fpm\.sock|\1|')

  if [ -z "$PHP_VERSION" ]; then
    echo "PHP version could not be determined from details-file."
    exit 1
  fi

  echo "Enabling required Apache modules..."
  sudo a2enmod proxy
  sudo a2enmod proxy_fcgi
  sudo a2enmod rewrite

  echo "Restarting services..."
  sudo systemctl restart apache2
  sudo systemctl restart nginx
  sudo systemctl restart php$PHP_VERSION-fpm
  sudo systemctl restart varnish

  if [ $? -eq 0 ]; then
    echo "Modules enabled and services restarted successfully."
  else
    echo "Failed to enable modules or restart services. Please check for errors."
    exit 1
  fi
}

# Execute the function
enable_modules_and_restart

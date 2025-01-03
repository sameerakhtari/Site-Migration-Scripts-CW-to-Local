#!/bin/bash

# Function to install Certbot and configure SSL
install_and_configure_ssl() {
  echo "Installing dependencies for Certbot..."
  sudo apt update
  sudo apt install -y python3 python3-venv libaugeas0

  echo "Setting up Certbot..."
  sudo python3 -m venv /opt/certbot/
  sudo /opt/certbot/bin/pip install --upgrade pip
  sudo /opt/certbot/bin/pip install certbot certbot-nginx
  sudo ln -s /opt/certbot/bin/certbot /usr/bin/certbot

  echo "Configuring SSL with Certbot..."
  ORGANIZATION_EMAIL=$(grep "^organization_email:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$ORGANIZATION_EMAIL" ]; then
    echo "Organization email not found in details-file. Please ensure it exists."
    exit 1
  fi

  echo "Running Certbot for SSL..."
  echo -e "$ORGANIZATION_EMAIL\nY\nY\n1\n" | sudo certbot --nginx --email "$ORGANIZATION_EMAIL" --agree-tos --no-eff-email --non-interactive --no-redirect

  echo "Setting up automated SSL renewal..."
  echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" | sudo tee -a /etc/crontab > /dev/null

  echo "Updating Certbot to the latest version..."
  sudo /opt/certbot/bin/pip install --upgrade certbot certbot-nginx

  echo "Certbot installation and SSL configuration completed."
}

# Execute the function
install_and_configure_ssl

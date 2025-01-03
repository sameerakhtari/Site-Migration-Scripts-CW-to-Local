#!/bin/bash

# Function to install and configure Nginx
install_and_configure_nginx() {
  echo "Installing Nginx..."
  sudo apt update
  sudo apt install -y nginx

  echo "Starting Nginx service..."
  sudo systemctl start nginx

  echo "Enabling Nginx to start on boot..."
  sudo systemctl enable nginx

  echo "Updating Nginx configuration..."

  SITE_URL=$(grep "^domain:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$SITE_URL" ]; then
    echo "Site URL not found in details-file. Please ensure it exists."
    exit 1
  fi

  sudo tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
    listen 80;
    server_name www.${SITE_URL};
    return 301 http://${SITE_URL}\$request_uri;
}

server {
    root /var/www/html/public_html;
    index index.php index.html index.htm index.nginx-debian.html;
    server_name ${SITE_URL};

    location / {
        proxy_pass http://127.0.0.1:6081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        try_files \$uri \$uri/ =404;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|otf|eot)$ {
        root /var/www/html/public_html;
        expires max;
        log_not_found off;
    }

    add_header Content-Security-Policy "upgrade-insecure-requests";
}
EOL

  echo "Restarting Nginx to apply changes..."
  sudo systemctl restart nginx

  echo "Nginx installation and configuration completed."
}

# Execute the function
install_and_configure_nginx

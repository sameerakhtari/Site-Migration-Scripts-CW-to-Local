#!/bin/bash

# Function to update NGINX configuration for Varnish failover
update_nginx_config() {
  # Path to the NGINX configuration file
  CONFIG_FILE="/etc/nginx/sites-available/default"

  # Check if the configuration file exists
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "NGINX configuration file not found at $CONFIG_FILE."
    exit 1
  fi

  # Backup the original configuration file
  echo "Backing up the original configuration file..."
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

  # Check if the failover settings are already present
  if grep -q "proxy_next_upstream error timeout http_502 http_503 http_504;" "$CONFIG_FILE"; then
    echo "Failover settings are already present in the configuration. No changes made."
    return
  fi

  # Update the configuration for Varnish failover
  echo "Updating NGINX configuration for Varnish failover..."
  sed -i \
    -e "/proxy_pass http:\/\/127.0.0.1:6081;/a \
    \        proxy_next_upstream error timeout http_502 http_503 http_504;" \
    "$CONFIG_FILE"

  # Test the NGINX configuration
  echo "Testing the updated NGINX configuration..."
  nginx -t
  if [ $? -ne 0 ]; then
    echo "NGINX configuration test failed. Restoring the original configuration..."
    mv "$CONFIG_FILE.bak" "$CONFIG_FILE"
    exit 1
  fi

  # Reload NGINX to apply changes
  echo "Reloading NGINX to apply changes..."
  systemctl reload nginx

  echo "NGINX configuration updated successfully."
}

# Execute the function
update_nginx_config

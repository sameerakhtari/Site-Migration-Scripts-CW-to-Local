#!/bin/bash

# Function to install and configure Varnish
install_and_configure_varnish() {
  echo "Installing Varnish..."
  sudo apt update
  sudo apt install -y varnish

  echo "Starting Varnish service..."
  sudo systemctl start varnish

  echo "Enabling Varnish to start on boot..."
  sudo systemctl enable varnish

  echo "Updating /etc/varnish/default.vcl..."
  sudo sed -i 's|\.port = "8080"|\.port = "8080"|' /etc/varnish/default.vcl

  if ! grep -q "sub vcl_recv" /etc/varnish/default.vcl; then
    echo "Adding custom vcl_recv logic..."
    sudo tee -a /etc/varnish/default.vcl > /dev/null <<EOL

sub vcl_recv {
    # Pass requests with session cookies
    if (req.http.Cookie ~ "(wordpress_logged_in_|PHPSESSID)") {
        return (pass);
    }

    # Remove cookies not needed for caching
    if (req.http.Cookie) {
        set req.http.Cookie = regsuball(req.http.Cookie, "(^|;)\\s*(wordpress_logged_in_[^;]+|PHPSESSID)=[^>]+", "");
        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        }
    }
}
EOL
  fi

  echo "Restarting Varnish to apply changes..."
  sudo systemctl restart varnish

  echo "Varnish installation and configuration completed."
}

# Execute the function
install_and_configure_varnish

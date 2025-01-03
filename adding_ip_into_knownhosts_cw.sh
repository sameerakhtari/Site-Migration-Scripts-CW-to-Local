#!/bin/bash

# Function to add the current server's IP to the Cloudways server's known hosts
add_ip_to_known_hosts() {
  # Load details from details-file
  PUBLIC_IP=$(grep "^remote_server_ip:" ./details-file | cut -d ' ' -f 2)
  USERNAME=$(grep "^remote_server_user:" ./details-file | cut -d ' ' -f 2)
  PASSWORD=$(grep "^remote_server_password:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$PUBLIC_IP" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    echo "Missing required details (public IP, username, or password) in details-file."
    exit 1
  fi

  # Get the current server's public IP
  CURRENT_IP=$(curl -s ifconfig.me)

  if [ -z "$CURRENT_IP" ]; then
    echo "Failed to retrieve the current server's public IP."
    exit 1
  fi

  echo "Adding current server's IP ($CURRENT_IP) to Cloudways server's known hosts..."

  # Use sshpass to automate SSH login and add IP to known hosts
  if ! command -v sshpass &> /dev/null; then
    echo "sshpass is not installed. Installing sshpass..."
    sudo apt update
    sudo apt install sshpass -y
  fi

  sshpass -p "$PASSWORD" ssh "$USERNAME@$PUBLIC_IP" "echo $CURRENT_IP >> ~/.ssh/known_hosts"

  if [ $? -eq 0 ]; then
    echo "Current server's IP successfully added to Cloudways server's known hosts."
  else
    echo "Failed to add current server's IP to Cloudways server's known hosts. Please check your details and try again."
    exit 1
  fi
}

# Execute the function
add_ip_to_known_hosts

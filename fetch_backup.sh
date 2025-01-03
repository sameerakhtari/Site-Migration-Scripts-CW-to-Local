#!/bin/bash

# Function to fetch backup from Cloudways server
fetch_backup() {
  # Load details from details-file
  PUBLIC_IP=$(grep "^remote_server_ip:" ./details-file | cut -d ' ' -f 2)
  USERNAME=$(grep "^remote_server_user:" ./details-file | cut -d ' ' -f 2)
  DB_NAME=$(grep "^db_name:" ./details-file | cut -d ' ' -f 2)
  PASSWORD=$(grep "^remote_server_password:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$PUBLIC_IP" ] || [ -z "$USERNAME" ] || [ -z "$DB_NAME" ] || [ -z "$PASSWORD" ]; then
    echo "Missing required details (public IP, username, password, or DB name) in details-file."
    exit 1
  fi

  # Backup file path on Cloudways server
  BACKUP_PATH="/applications/$DB_NAME/local_backups/backup.tgz"

  # Destination path on the local server
  LOCAL_DEST="./backup.tgz"

  echo "Fetching backup from Cloudways server..."

  # Use sshpass to automate SSH with password
  if ! command -v sshpass &> /dev/null; then
    echo "sshpass is not installed. Installing sshpass..."
    sudo apt update
    sudo apt install sshpass -y
  fi

  # Attempt to bypass host key verification only if needed
  echo "Checking for host key verification..."
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$USERNAME@$PUBLIC_IP" exit 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Host key not verified. Adding it to known hosts..."
    ssh-keyscan -H "$PUBLIC_IP" >> ~/.ssh/known_hosts 2>/dev/null
  fi

  # Fetch the backup file using scp
  sshpass -p "$PASSWORD" scp "$USERNAME@$PUBLIC_IP:$BACKUP_PATH" "$LOCAL_DEST"

  if [ $? -eq 0 ]; then
    echo "Backup successfully fetched to $LOCAL_DEST."
  else
    echo "Failed to fetch backup. Please check your details and try again."
    exit 1
  fi
}

# Execute the function
fetch_backup

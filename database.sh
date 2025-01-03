#!/bin/bash

# Function to install MariaDB, create database, user, and import data
setup_database() {
  # Load details from details-file
  DB_NAME=$(grep "^db_name:" ./details-file | cut -d ' ' -f 2)
  DB_USER=$(grep "^db_user:" ./details-file | cut -d ' ' -f 2)
  DB_PASSWORD=$(grep "^db_password:" ./details-file | cut -d ' ' -f 2)
  DOCUMENT_ROOT=$(grep "^document_root:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DOCUMENT_ROOT" ]; then
    echo "Database name, user, password, or document root is missing in details-file."
    exit 1
  fi

  # Install MariaDB if not installed
  echo "Checking for MariaDB installation..."
  if ! command -v mysql &> /dev/null; then
    echo "MariaDB is not installed. Installing MariaDB..."
    sudo apt update
    sudo apt install mariadb-server -y
    sudo systemctl enable mariadb
    sudo systemctl start mariadb
  fi

  # Secure MariaDB installation
  echo "Securing MariaDB installation..."
  sudo mysql_secure_installation <<EOF
n
y
y
y
y
EOF

  # Create database and user
  echo "Setting up database and user..."
  sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"
  sudo mysql -u root -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
  sudo mysql -u root -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'localhost';"
  sudo mysql -u root -e "FLUSH PRIVILEGES;"

  # Locate the SQL file to import
  SQL_FILE="./${DB_NAME}-backup/${DB_NAME}*.sql"
  SQL_FILE_MATCH=$(ls $SQL_FILE 2>/dev/null | head -n 1)

  if [ -z "$SQL_FILE_MATCH" ]; then
    echo "SQL file matching pattern $SQL_FILE not found."
    exit 1
  fi

  # Import the SQL file
  echo "Importing SQL file $SQL_FILE_MATCH into database $DB_NAME..."
  sudo mysql -u root "$DB_NAME" < "$SQL_FILE_MATCH"

  if [ $? -eq 0 ]; then
    echo "Database imported successfully."
  else
    echo "Failed to import database."
    exit 1
  fi

  # Remove index.html if it exists
  INDEX_FILE="$DOCUMENT_ROOT/index.html"
  if [ -f "$INDEX_FILE" ]; then
    echo "Removing $INDEX_FILE..."
    rm "$INDEX_FILE"
  fi

  # Update wp-config.php
  WP_CONFIG="$DOCUMENT_ROOT/wp-config.php"
  if [ -f "$WP_CONFIG" ]; then
    echo "Updating WP_REDIS_DISABLED in $WP_CONFIG..."
    sed -i "s/define( 'WP_REDIS_DISABLED', false );/define( 'WP_REDIS_DISABLED', true );/" "$WP_CONFIG"
  else
    echo "$WP_CONFIG not found. Skipping update."
  fi
}

# Execute the function
setup_database

#!/bin/bash

# Function to extract and move backup files
process_backup() {
  # Load details from details-file
  DB_NAME=$(grep "^db_name:" ./details-file | cut -d ' ' -f 2)
  DEST_DIR=$(grep "^document_root:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$DB_NAME" ]; then
    echo "Database name (db_name) is missing in details-file."
    exit 1
  fi

  if [ -z "$DEST_DIR" ]; then
    echo "Document root (document_root) is missing in details-file."
    exit 1
  fi

  # Define paths
  BACKUP_FILE="./backup.tgz"
  EXTRACT_DIR="./${DB_NAME}-backup"

  # Check if the backup file exists
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file $BACKUP_FILE not found."
    exit 1
  fi

  # Create the extraction directory
  echo "Creating extraction directory $EXTRACT_DIR..."
  mkdir -p "$EXTRACT_DIR"

  # Extract the backup file
  echo "Extracting $BACKUP_FILE into $EXTRACT_DIR..."
  tar -xvzf "$BACKUP_FILE" -C "$EXTRACT_DIR"

  if [ $? -ne 0 ]; then
    echo "Failed to extract the backup file."
    exit 1
  fi

  # Move files from extracted public_html to destination
  echo "Moving files from $EXTRACT_DIR/public_html to $DEST_DIR..."
  if [ -d "$EXTRACT_DIR/public_html" ]; then
    mkdir -p "$DEST_DIR"
    cp -R "$EXTRACT_DIR/public_html"/* "$DEST_DIR"

    if [ $? -eq 0 ]; then
      echo "Files successfully moved to $DEST_DIR."
    else
      echo "Failed to move files to $DEST_DIR."
      exit 1
    fi
  else
    echo "$EXTRACT_DIR/public_html does not exist. Please verify the backup structure."
    exit 1
  fi
}

# Execute the function
process_backup

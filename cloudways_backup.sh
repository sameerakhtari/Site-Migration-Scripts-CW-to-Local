#!/bin/bash

# Function to initiate a backup and monitor its status
initiate_and_monitor_backup() {
  # Ensure jq is installed
  echo "Checking for jq installation..."
  if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    sudo apt update
    sudo apt install jq -y
  fi

  # Load API key, email, and server ID from details-file
  API_KEY=$(grep "^api_key:" ./details-file | cut -d ' ' -f 2)
  EMAIL=$(grep "^organization_email:" ./details-file | cut -d ' ' -f 2)
  SERVER_ID=$(grep "^server_id:" ./details-file | cut -d ' ' -f 2)

  if [ -z "$API_KEY" ] || [ -z "$EMAIL" ] || [ -z "$SERVER_ID" ]; then
    echo "API key, email, or server ID not found in details-file. Please ensure they exist."
    exit 1
  fi

  # Authenticate with Cloudways API
  echo "Authenticating with Cloudways API..."
  AUTH_RESPONSE=$(curl -s -X POST "https://api.cloudways.com/api/v1/oauth/access_token" \
    -H "Content-Type: application/json" \
    -d '{"email": "'$EMAIL'", "api_key": "'$API_KEY'"}')

  ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token')

  if [ -z "$ACCESS_TOKEN" ]; then
    echo "Authentication failed. Please check your API key and email."
    exit 1
  fi

  echo "Authentication successful. Token obtained."

  # Trigger a backup
  echo "Initiating backup for Server ID: $SERVER_ID..."
  BACKUP_RESPONSE=$(curl -s -L -X POST "https://api.cloudways.com/api/v1/server/manage/backup" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "server_id=$SERVER_ID")

  echo "Backup Response: $BACKUP_RESPONSE"

  OPERATION_ID=$(echo "$BACKUP_RESPONSE" | jq -r '.operation_id // .operation.id')

  if [ -z "$OPERATION_ID" ] || [ "$OPERATION_ID" == "null" ]; then
    echo "Failed to retrieve an operation ID. Response: $BACKUP_RESPONSE"
    exit 1
  fi

  echo "Backup initiated successfully with Operation ID: $OPERATION_ID. Monitoring backup status..."

  # Monitor the backup status
  while :; do
    STATUS_RESPONSE=$(curl -s -L -X GET "https://api.cloudways.com/api/v1/operation/$OPERATION_ID" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json")

    echo "Status Response: $STATUS_RESPONSE"

    if echo "$STATUS_RESPONSE" | jq .operation &> /dev/null; then
      CURRENT_STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.operation.status')
      IS_COMPLETED=$(echo "$STATUS_RESPONSE" | jq -r '.operation.is_completed')

      if [ "$IS_COMPLETED" == "1" ]; then
        echo "Backup completed successfully. Status: $CURRENT_STATUS"
        break
      elif [ "$IS_COMPLETED" == "0" ]; then
        echo "Backup in progress. Status: $CURRENT_STATUS. Waiting..."
        sleep 30
      else
        echo "Unexpected completion status: $IS_COMPLETED. Status: $CURRENT_STATUS"
        exit 1
      fi
    else
      echo "Unexpected response from API. Please verify the operation ID and token."
      exit 1
    fi
  done
}

# Execute the function
initiate_and_monitor_backup

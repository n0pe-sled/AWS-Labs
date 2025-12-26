#!/bin/bash
set -e

# Accept user name as parameter or use default
USER_NAME="${1:-specter-lab-createcredentials-privileged}"
echo "Starting cleanup for user: $USER_NAME"

# Delete login profile if it exists
echo "Checking for login profile..."
if aws iam get-login-profile --user-name $USER_NAME 2>/dev/null; then
  echo "Deleting login profile..."
  aws iam delete-login-profile --user-name $USER_NAME || echo "Failed to delete login profile"
else
  echo "No login profile found"
fi

# List and delete all access keys
echo "Checking for access keys..."
ACCESS_KEYS=$(aws iam list-access-keys --user-name $USER_NAME --query 'AccessKeyMetadata[].AccessKeyId' --output text 2>/dev/null || echo "")
if [ -n "$ACCESS_KEYS" ] && [ "$ACCESS_KEYS" != "None" ]; then
  for key_id in $ACCESS_KEYS; do
    echo "Deleting access key: $key_id"
    aws iam delete-access-key --user-name $USER_NAME --access-key-id $key_id || echo "Failed to delete access key: $key_id"
  done
else
  echo "No access keys found"
fi

echo "Manual cleanup complete"
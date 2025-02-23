#!/bin/bash
# Ensure you run this script from the root of your Git repository
# and that you are authenticated with GitHub CLI.

# Read the keystore Base64 string
KEYS_BASE64=$(cat keystore_base64.txt)

# Replace these placeholders with your actual values
KEYSTORE_STORE_PASSWORD="YOUR_KEYSTORE_STORE_PASSWORD"
KEY_ALIAS="YOUR_KEY_ALIAS"
KEYSTORE_KEY_PASSWORD="YOUR_KEYSTORE_KEY_PASSWORD"

echo "Setting secrets for repository..."

# Create the secrets using GitHub CLI
gh secret set KEYSTORE_BASE64 --body "$KEYS_BASE64"
gh secret set KEYSTORE_STORE_PASSWORD --body "$KEYSTORE_STORE_PASSWORD"
gh secret set KEY_ALIAS --body "$KEY_ALIAS"
gh secret set KEYSTORE_KEY_PASSWORD --body "$KEYSTORE_KEY_PASSWORD"

echo "Secrets have been set successfully."
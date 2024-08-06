#!/bin/bash

# Activate the virtual environment
source /opt/venv/bin/activate

# Configure Aliyun CLI
aliyun configure set --profile akProfile --mode AK --region $REGION --access-key-id $ACCESS_KEY_ID --access-key-secret $ACCESS_KEY_SECRET

# Obtain the certificate
certbot certonly -d "$DOMAIN" --manual --preferred-challenges dns --manual-auth-hook "/usr/local/bin/alidns" --manual-cleanup-hook "/usr/local/bin/alidns clean" --agree-tos --email $EMAIL --non-interactive

# Start cron daemon
crond -f -l 2


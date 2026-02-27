#!/bin/bash

# Activate the virtual environment
source /opt/venv/bin/activate

# Configure Aliyun CLI
aliyun configure set --profile akProfile --mode AK --region $REGION --access-key-id $ACCESS_KEY_ID --access-key-secret $ACCESS_KEY_SECRET

# Obtain the certificate
certbot certonly -d "$DOMAIN" --manual --preferred-challenges dns --manual-auth-hook "/usr/local/bin/alidns" --manual-cleanup-hook "/usr/local/bin/alidns clean" --agree-tos --email $EMAIL --non-interactive

# Setup cron job for certbot renew dynamically
echo "$CRON_SCHEDULE /opt/venv/bin/certbot renew --manual --preferred-challenges dns --manual-auth-hook '/usr/local/bin/alidns' --manual-cleanup-hook '/usr/local/bin/alidns clean' --agree-tos --email $EMAIL --deploy-hook \"cp -r /etc/letsencrypt/live/\\\$DOMAIN/* /etc/letsencrypt/certs\"" > /etc/crontabs/root

# Start cron daemon
crond -f -l 2

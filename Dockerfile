FROM alpine:latest

# Install dependencies
RUN apk --no-cache add wget tar sudo certbot bash python3 py3-pip && \
    apk --no-cache add --virtual build-dependencies gcc musl-dev python3-dev libffi-dev openssl-dev make

# Install aliyun-cli
RUN wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz && \
    tar xzvf aliyun-cli-linux-latest-amd64.tgz && \
    mv aliyun /usr/local/bin && \
    rm aliyun-cli-linux-latest-amd64.tgz

# Copy and install certbot-dns-aliyun plugin
RUN wget https://cdn.jsdelivr.net/gh/justjavac/certbot-dns-aliyun@main/alidns.sh && \
    mv alidns.sh /usr/local/bin/alidns && \
    chmod +x /usr/local/bin/alidns

# Create virtual environment for Python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies in virtual environment
RUN pip install --upgrade pip && \
    pip install aliyun-python-sdk-core aliyun-python-sdk-alidns

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables (to be provided during runtime)
ENV REGION=""
ENV ACCESS_KEY_ID=""
ENV ACCESS_KEY_SECRET=""
ENV DOMAIN=""
ENV EMAIL=""
ENV CRON_SCHEDULE="0 0 * * *"

# Setup cron job for certbot renew
RUN echo "$CRON_SCHEDULE /opt/venv/bin/certbot renew --manual --preferred-challenges dns --manual-auth-hook '/usr/local/bin/alidns' --manual-cleanup-hook '/usr/local/bin/alidns clean' --agree-tos --email $EMAIL --deploy-hook 'cp -r /etc/letsencrypt/live/$DOMAIN/* /etc/letsencrypt/certs'" > /etc/crontabs/root

# Create directory for certificates
RUN mkdir -p /etc/letsencrypt/certs

# Make sure cron is running
RUN touch /var/log/cron.log

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]


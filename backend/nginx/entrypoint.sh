#!/bin/sh
# nginx/entrypoint.sh
#
# Bootstrap script for nginx SSL certificates.
#
# If Let's Encrypt certificates exist in the shared volume:
#   → copy them to /etc/nginx/ssl/ (writable, inside container)
# If not:
#   → generate temporary self-signed certificates so nginx can start
#     (real certs will be obtained later via init-letsencrypt.sh)
#
# nginx.conf always references certs at /etc/nginx/ssl/.

set -e

LETSENCRYPT_DIR="/etc/letsencrypt/live/myexchange.online"
NGINX_SSL_DIR="/etc/nginx/ssl"

# ── Prepare SSL certificates ───────────────────────────────────
mkdir -p "$NGINX_SSL_DIR"

if [ -f "$LETSENCRYPT_DIR/fullchain.pem" ] && [ -f "$LETSENCRYPT_DIR/privkey.pem" ]; then
    echo "✓ Let's Encrypt certificates found. Copying to $NGINX_SSL_DIR/ …"
    cp -L "$LETSENCRYPT_DIR/fullchain.pem" "$NGINX_SSL_DIR/fullchain.pem"
    cp -L "$LETSENCRYPT_DIR/privkey.pem"   "$NGINX_SSL_DIR/privkey.pem"
else
    echo "⚠ Let's Encrypt certificates not found. Generating temporary self-signed certs."
    echo "  Run ./init-letsencrypt.sh to obtain real certificates."

    openssl req -x509 \
        -nodes \
        -days 90 \
        -newkey rsa:4096 \
        -keyout "$NGINX_SSL_DIR/privkey.pem" \
        -out "$NGINX_SSL_DIR/fullchain.pem" \
        -subj "/C=KG/ST=Bishkek/L=Bishkek/O=My Exchange/CN=myexchange.online" \
        -addext "subjectAltName=DNS:myexchange.online,DNS:api.myexchange.online" \
        2>/dev/null

    echo "✓ Temporary self-signed certificates created at $NGINX_SSL_DIR/"
fi

# ── Start nginx ────────────────────────────────────────────────
echo "Starting nginx…"
exec nginx -g "daemon off;"

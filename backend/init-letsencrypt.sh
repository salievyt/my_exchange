#!/bin/bash
#
# init-letsencrypt.sh
# Initialises Let's Encrypt SSL certificates for myexchange.online
# and api.myexchange.online using the certbot Docker image with webroot mode.
#
# Prerequisites:
#   - nginx container must be running (docker compose up -d nginx)
#   - DNS A records for myexchange.online and api.myexchange.online
#     must point to this server's public IP
#   - Ports 80 and 443 must be open on the firewall
#

set -euo pipefail

DOMAINS="myexchange.online api.myexchange.online"
PRIMARY_DOMAIN="myexchange.online"
EMAIL="${EMAIL:-admin@myexchange.online}"

RSA_KEY_SIZE=4096

# Determine project root (parent of the directory containing this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

echo "============================================"
echo "  Let's Encrypt Certificate Initialisation"
echo "============================================"
echo ""
echo "Domains : $DOMAINS"
echo "Email   : $EMAIL"
echo "Data dir: $PROJECT_ROOT/certbot"
echo ""

# ── Create required directories ────────────────────────────────
mkdir -p "$PROJECT_ROOT/certbot/conf"
mkdir -p "$PROJECT_ROOT/certbot/www"

# ── Verify nginx is running ────────────────────────────────────
if ! docker compose ps nginx 2>/dev/null | grep -q "Up"; then
    echo "Starting nginx (HTTP-only bootstrap) ..."
    docker compose up -d nginx
    echo "Waiting for nginx to be ready..."
    sleep 5
fi

# ── Get the certificate via webroot ────────────────────────────
echo ""
echo "=== Requesting certificate via HTTP-01 (webroot) ==="
echo "nginx must be reachable on port 80 from the internet."
echo ""

docker compose run --rm --entrypoint certbot certbot certonly \
    --webroot -w /var/www/certbot \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --rsa-key-size "$RSA_KEY_SIZE" \
    --domains "$(echo $DOMAINS | tr ' ' ',')" \
    --force-renewal

echo ""
echo "=== Certificate obtained successfully! ==="
echo ""
echo "Certificate path: $PROJECT_ROOT/certbot/conf/live/$PRIMARY_DOMAIN/"
echo ""

# ── Restart nginx to pick up real certificates ─────────────────
echo "Restarting nginx to load real certificates..."
docker compose restart nginx

echo ""
echo "=== Done ==="
echo ""
echo "Your site is now available at:"
echo "  https://$PRIMARY_DOMAIN"
echo "  https://api.$PRIMARY_DOMAIN"
echo ""
echo "Auto-renewal runs every 12 hours via the certbot service."
echo ""
echo "To test renewal:"
echo "  docker compose run --rm certbot renew --dry-run"

FROM nginx:alpine

# Install openssl CLI for generating temporary self-signed certificates
RUN apk add --no-cache openssl

# Copy configuration and entrypoint
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]

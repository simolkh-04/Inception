FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/mlakhal.42.fr.key \
    -out /etc/nginx/ssl/mlakhal.42.fr.crt \
    -subj "/C=MA/ST=Rabat/L=Rabat/O=42/OU=42/CN=mlakhal.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
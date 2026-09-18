FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
    php8.2 \
    php8.2-mysql \
    wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html && \
    wget https://www.adminer.org/latest.php \
    -O /var/www/html/index.php

EXPOSE 8080

CMD ["php", "-S", "0.0.0.0:8080", "-t", "/var/www/html"]
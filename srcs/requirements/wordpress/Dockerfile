FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-redis \
    curl \
    mariadb-client

RUN sed -i 's|^listen = .*|listen = 9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf

RUN mkdir -p /var/www/html && \
    curl -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz && \
    tar -xzf /tmp/wordpress.tar.gz -C /tmp && \
    cp -a /tmp/wordpress/. /var/www/html/ && \
    rm -rf /tmp/wordpress /tmp/wordpress.tar.gz

RUN chown -R www-data:www-data /var/www/html

RUN mkdir -p /run/php

COPY tools/setup.sh /usr/local/bin/setup.sh

RUN chmod +x /usr/local/bin/setup.sh

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

ENTRYPOINT ["/usr/local/bin/setup.sh"]
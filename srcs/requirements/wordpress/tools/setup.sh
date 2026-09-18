#!/bin/bash

set -e

MYSQL_DATABASE="${MYSQL_DATABASE}"
MYSQL_USER="${MYSQL_USER}"

MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

DB_HOST="mariadb"
DB_PORT="3306"

until mariadb -h"$DB_HOST" -P"$DB_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1
do
    echo "Waiting for MariaDB..."
    sleep 2
done

echo "MariaDB is ready!"

if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Creating wp-config.php..."

cat > /var/www/html/wp-config.php <<EOF
<?php

define('DB_NAME', '${MYSQL_DATABASE}');
define('DB_USER', '${MYSQL_USER}');
define('DB_PASSWORD', '${MYSQL_PASSWORD}');
define('DB_HOST', '${DB_HOST}:${DB_PORT}');

define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = 'wp_';

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

define('WP_REDIS_HOST', 'redis');
define('WP_REDIS_PORT', 6379);

require_once ABSPATH . 'wp-settings.php';

EOF

else
    echo "wp-config.php already exists."
fi

if wp core is-installed --path=/var/www/html --allow-root; then
    echo "WordPress is already installed."
else
    echo "Installing WordPress..."

    wp core install \
        --path=/var/www/html \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    echo "WordPress installed successfully."
fi

if wp user get user42 --path=/var/www/html --allow-root > /dev/null 2>&1; then
    echo "User user42 already exists."
else
    echo "Creating WordPress user user42..."

    wp user create user42 user42@example.com \
        --role=subscriber \
        --user_pass="$WP_USER_PASSWORD" \
        --path=/var/www/html \
        --allow-root

    echo "WordPress user user42 created."
fi

echo "Starting PHP-FPM..."

exec php-fpm8.2 -F
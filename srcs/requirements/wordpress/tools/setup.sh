#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

WP_DIR="/var/www/html"

echo "Waiting for MariaDB..."
until mysql -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; do
    sleep 2
done

if [ ! -f "${WP_DIR}/wp-config.php" ]; then
    echo "Installing WordPress..."
    
    cd ${WP_DIR}

    # Zedt hna --skip-content bach maytle3ch lik Error dyal files already present
    wp core download --allow-root --skip-content || true

    wp config create \
        --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="mariadb"

    # WordPress Core Install (Khas darouri tkon qbel plugins)
    wp core install \
        --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    wp user create \
        --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=editor \
        --user_pass="${WP_USER_PASSWORD}"

    # Redis config w Plugins (kayjiw hna f l-lkher)
    wp config set WP_REDIS_HOST 'redis' --allow-root --path=${WP_DIR}
    wp config set WP_REDIS_PORT 6379 --raw --allow-root --path=${WP_DIR}
    wp config set WP_CACHE true --raw --allow-root --path=${WP_DIR}
    wp plugin install redis-cache --activate --allow-root
    wp redis enable --allow-root
    
    echo "WordPress setup complete!"
else
    echo "WordPress already configured, skipping setup."
fi

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
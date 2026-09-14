#!/bin/bash

set -e

MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

mariadbd --user=mysql --skip-networking &
pid="$!"

until mariadb-admin ping --silent; do
    sleep 1
done

echo "MariaDB is ready for initialization."

if mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1;" > /dev/null 2>&1; then
    echo "Root password already configured."
else
    echo "Configuring root password..."

    mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
EOF
fi

echo "Creating database and user..."

mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

FLUSH PRIVILEGES;
EOF

echo "Database and user configured."

mysqladmin -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

wait "$pid"

echo "Starting MariaDB..."

exec mariadbd --user=mysql --console
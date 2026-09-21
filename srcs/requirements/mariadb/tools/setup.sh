#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# 1. Hna zedt l-initialisation dyal l-base de données ila kant khawya
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Installing MariaDB system tables..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null
fi

mysqld --user=mysql --skip-networking &
MYSQLD_PID=$!

while ! mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent 2>/dev/null; do
    sleep 1
done

mysql --socket=/run/mysqld/mysqld.sock << SQL
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL

mysqladmin shutdown --socket=/run/mysqld/mysqld.sock -u root -p"${DB_ROOT_PASSWORD}"
wait $MYSQLD_PID

exec mysqld --user=mysql
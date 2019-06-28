#!/bin/bash
echo "Now in launcher.sh"

# Create a bunch of folders under the clean /var that php, nginx, and mysql expect to exist
mkdir -p /var/lib/mysql
#mkdir -p /var/lib/mysql-files
mkdir -p /var/lib/nginx
mkdir -p /var/lib/php/sessions
mkdir -p /var/log
mkdir -p /var/log/mysql
mkdir -p /var/log/nginx
# Wipe /var/run, since pidfiles and socket files from previous launches should go away
# TODO someday: I'd prefer a tmpfs for these.
rm -rf /var/run
mkdir -p /var/run/php
rm -rf /var/tmp
mkdir -p /var/tmp
mkdir -p /var/run/mysqld

#make storage directories
rm -rf /var/storage
mkdir -p /var/storage/app/public
mkdir -p /var/storage/build
mkdir -p /var/storage/system/core/
mkdir -p /var/storage/database
mkdir -p /var/storage/debugbar
mkdir -p /var/storage/export
mkdir -p /var/storage/framework/cache/v1
mkdir -p /var/storage/framework/sessions
mkdir -p /var/storage/framework/views/v1
mkdir -p /var/storage/logs
mkdir -p /var/storage/upload

cp -r /opt/app/ /var/www/

# Ensure mysql tables created
HOME=/etc/mysql /usr/bin/mysql_install_db --force
#HOME=/etc/mysql /usr/sbin/mysqld --initialize

# Spawn mysqld, php
HOME=/etc/mysql /usr/sbin/mysqld &
/usr/sbin/php-fpm7.2 --nodaemonize --fpm-config /etc/php/7.2/fpm/php-fpm.conf &
# Wait until mysql and php have bound their sockets, indicating readiness
while [ ! -e /var/run/mysqld/mysqld.sock ] ; do
    echo "waiting for mysql to be available at /var/run/mysqld/mysqld.sock"
    sleep .5
done
while [ ! -e /var/run/php7.2-fpm.sock ] ; do
    echo "waiting for php7.2-fpm to be available at /var/run/php7.2-fpm.sock"
    sleep .5
done


echo "Installing database.."
# Install database for jorani
echo "CREATE DATABASE IF NOT EXISTS jorani; GRANT ALL on jorani.* TO 'jorani'@'localhost' IDENTIFIED BY 'jorani';use jorani;source /opt/app/sql/jorani.sql;
" | mysql -u root
mysql --print-defaults
echo "Done!"

# Start nginx.
/usr/sbin/nginx -c /opt/app/.sandstorm/service-config/nginx.conf -g "daemon off;"

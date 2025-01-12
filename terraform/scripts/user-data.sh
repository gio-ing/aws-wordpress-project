#!/bin/bash

# Log output per debugging
exec > /var/log/user-data.log 2>&1

# Parametri passati da Terraform
DB_USER="$${db_user}"
DB_NAME="$${db_name}"
DB_PWD="$${db_pwd}"
DB_ENDPOINT="$${db_endpoint}"
REGION="$${region}"
WP_VERSION="$${wp_version:-latest}"
EFS_DNS="$${efs_dns}"

# Aggiornamento dei pacchetti
yum update -y

# Installazione di Apache
yum install -y httpd

# Abilita Apache e avvia il servizio
systemctl enable httpd
systemctl start httpd

# Installazione di PHP
amazon-linux-extras enable php8.0
yum clean metadata
yum install -y php php-mysqlnd php-fpm php-json

# Installazione di MariaDB client
yum install -y mariadb

# Installazione del client Amazon EFS
yum install -y amazon-efs-utils

# Creazione della directory WordPress
mkdir -p /var/www/html

# Montaggio del file system EFS
echo "$${EFS_DNS}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab
mount -a

# Scarica la versione di WordPress specificata
if [ "$WP_VERSION" == "latest" ]; then
    wget https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
else
    wget https://wordpress.org/wordpress-$${WP_VERSION}.tar.gz -O /tmp/wordpress.tar.gz
fi

# Estrai WordPress
tar -xzf /tmp/wordpress.tar.gz -C /tmp/
cp -r /tmp/wordpress/* /var/www/html/
rm -rf /tmp/wordpress /tmp/wordpress.tar.gz

# Imposta i permessi corretti
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

# Configurazione del file wp-config.php
cat <<EOL > /var/www/html/wp-config.php
<?php
define('DB_NAME', '$${DB_NAME}');
define('DB_USER', '$${DB_USER}');
define('DB_PASSWORD', '$${DB_PWD}');
define('DB_HOST', '$${DB_ENDPOINT}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
\$table_prefix = 'wp_';
define('WP_DEBUG', false);
if ( ! defined('ABSPATH') ) {
    define('ABSPATH', dirname(__FILE__) . '/');
}
require_once ABSPATH . 'wp-settings.php';
EOL

# Riavvia Apache
systemctl restart httpd

echo "WordPress installato con successo!"

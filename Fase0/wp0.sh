#!/bin/bash

# Configuramos para ver los pasos
set -x

#VARIABLES
DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=wordpress_password
IP_PRIVADA_FRONT=localhost
IP_MYSQL_SERVER=localhost
WP_SITEURL=54.208.191.174
WP_HOME=54.208.191.174

#Actualizamos lista de paquetes
apt update

#Instalamos apache
apt install apache2 -y

#Instalamos MySQL Server
apt install mysql-server -y

#Instalamos los módulos PHP
apt install php libapache2-mod-php php-mysql -y

#Reiniciamos el servicio de Apache
systemctl restart apache2

#Copiamos el archivo info.php a /var/www/html
cp info.php /var/www/html

# Descargamos la ultima version de wordpress
cd /var/www/html
wget http://wordpress.org/latest.tar.gz

# Eliminamos instalaciones anteriores
rm -rf /var/www/html/wordpress

#Descomprimimos el .tar.gz
tar -xzvf latest.tar.gz

#Eliminamos el tar.gz
rm latest.tar.gz

#Creamos la base de datos para wordpress
mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME;"
mysql -u root <<< "CREATE DATABASE $DB_NAME;"
mysql -u root <<< "DROP USER IF EXISTS $DB_USER@$IP_PRIVADA_FRONT;"
mysql -u root <<< "CREATE USER $DB_USER@$IP_PRIVADA_FRONT IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@$IP_PRIVADA_FRONT;"
mysql -u root <<< "FLUSH PRIVILEGES;"

#Configuramos  el archivo de configuración de Wordpress
cd /var/www/html/wordpress
mv wp-config-sample.php wp-config.php

sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
sed -i "s/localhost/$IP_MYSQL_SERVER/" wp-config.php

# Configuramos la direccion de wordpress y direccion del sitio
echo "define('WP_SITEURL', 'http://$WP_SITEURL/wordpress');" >> wp-config.php
echo "define('WP_HOME', 'http://$WP_HOME');" >> wp-config.php

# Copiamos el archivo wordpress/index.php a /var/www/html
cp index.php /var/www/html

# Editamos el index.php
sed -i "s#wp-blog-header.php#wordpress/wp-blog-header.php#" /var/www/html/index.php

# Habilitamos el módulo mod_rewrite de apache
a2enmod rewrite
systemctl restart apache2

# Copiamos el archivo htacces a /var/www/html
cp /home/ubuntu/htaccess /var/www/html/

# Editamos el archivo 000-default de Apache
cp /home/ubuntu/000-default.conf /etc/apache2/sites-available/

#Configuramos las security keys en el archivo wp-config.php
sed -i "/AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_KEY/d" /var/www/html/wordpress/wp-config.php
sed -i "/AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/SECURE_AUTH_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/LOGGED_IN_SALT/d" /var/www/html/wordpress/wp-config.php
sed -i "/NONCE_SALT/d" /var/www/html/wordpress/wp-config.php

#Hacemos una llamada a la API de wordpress para obtener las security keys
SECURITY_KEYS=$(curl https://api.wordpress.org/secret-key/1.1/salt/)

#Reemplaza el carácter / por el carácter _
SECURITY_KEYS=$(echo $SECURITY_KEY | tr / _)

#Añadimos los security keys al archivo
sed -i "/@-/a $SECURITY_KEYS" /var/www/html/wordpress/wp-config.php

# Eliminamos el index.html de /var/www/html
rm /var/www/html/index.html

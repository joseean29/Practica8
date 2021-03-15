#!/bin/bash

# Configuramos para ver los pasos
set -x

#VARIABLES
DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=wordpress_password
IP_PRIVADA_MYSQL_SERVER=172.31.46.165
IP_PUBLICA_BALANCEADOR=3.86.203.126
IP_PRIVADA_FRONT_NFS_SERVER=172.31.89.59

#Actualizamos lista de paquetes
apt update

#Instalamos apache
apt install apache2 -y

#Instalamos los módulos PHP
apt install php libapache2-mod-php php-mysql -y

#Reiniciamos el servicio de Apache
systemctl restart apache2

#Copiamos el archivo info.php a /var/www/html
cp info.php /var/www/html

# Habilitamos el módulo mod_rewrite de apache
a2enmod rewrite
systemctl restart apache2

# Copiamos el archivo htacces a /var/www/html
cp /home/ubuntu/htaccess /var/www/html/.htaccess

# Editamos el archivo 000-default de Apache
cp /home/ubuntu/000-default.conf /etc/apache2/sites-available/

# Instalamos paquetes necesarios para cliente NFS
apt-get install nfs-common -y

# Montamos el directorio compartido entre frontales
mount $IP_PRIVADA_FRONT_NFS_SERVER:/var/www/html /var/www/html

# Configuramos el archivo /etc/fstab
echo "$IP_PRIVADA_FRONT_NFS_SERVER:/var/www/html/ /var/www/html  nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" > /etc/fstab

# Cambiamos grupo y propietario al directorio /var/www/html
chown www-data:www-data /var/www/html/ -R
#!/bin/bash

# Configuramos para ver los pasos
set -x

#VARIABLES
DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=wordpress_password
IP_PRIVADA_FRONT=
IP_PRIVADA_MYSQL=

#Actualizamos lista de paquetes
apt update

#Instalamos MySQL Server
apt install mysql-server -y

#Creamos la base de datos para wordpress
mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME;"
mysql -u root <<< "CREATE DATABASE $DB_NAME;"
mysql -u root <<< "DROP USER IF EXISTS $DB_USER@IP_PRIVADA_FRONT;"
mysql -u root <<< "CREATE USER $DB_USER@$IP_PRIVADA_FRONT IDENTIFIED BY '$DB_PASSWORD';"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO $DB_USER@$IP_PRIVADA_FRONT;"
mysql -u root <<< "FLUSH PRIVILEGES;"

# Configuramos MySQL para permitir conexiones desde la IP privada de la instancia
sed -i "s/127.0.0.1/$IP_PRIVADA_MYSQL/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciamos mysql
systemctl restart mysql
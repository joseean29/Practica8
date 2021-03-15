#!/bin/bash

# Configuramos el script para que se muestren los pasos
set -x

#---------------------------------------------------------
# variables de configuracion
#---------------------------------------------------------
IP_PRIVADA_FRONT_1=35.173.220.18
IP_PRIVADA_FRONT_2=3.85.130.95
#---------------------------------------------------------

# Instalamos el Servidor apache HTTP Server
apt install apache2 -y

#Habilitamos los modulos de Apache para configurar proxy inverso
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_ajp
a2enmod rewrite
a2enmod deflate
a2enmod headers
a2enmod proxy_balancer
a2enmod proxy_connect
a2enmod proxy_html
a2enmod lbmethod_byrequests

# Copiamos el archivo de configuración de Apache
cp 000-default.conf /etc/apache2/sites-available/

# Reemplazamos los valores IP-HTTP-SERVER-1 y IP-HTTP-SERVER-2
sed -i "s/IP-HTTP-SERVER-1/$IP_PRIVADA_FRONT_1/" /etc/apache2/sites-available/000-default.conf
sed -i "s/IP-HTTP-SERVER-2/$IP_PRIVADA_FRONT_2/" /etc/apache2/sites-available/000-default.conf

# Reiniciamos el servicio Apache
systemctl restart apache2
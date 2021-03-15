# 1 Práctica 8: Implantación de Wordpress en Amazon Web Services (AWS) sobre la pila LAMP
En esta práctica tendremos que realizar la instalación de un sitio WordPress haciendo uso de los servicios de Amazon Web Services (AWS)

Despliega la última versión de Worpress utilizando la siguiente arquitectura propuesta:
![]()

La arquitectura estará formada por:
- Un balanceador de carga, implementado con un Apache HTTP Server configurado como proxy inverso.
- Una capa de front-end, formada por dos servidores web con Apache HTTP Server.
- Una capa de back-end, formada por un servidor MySQL.

Necesitará crear las siguientes máquinas virtuales:
- Balanceador.
- Frontal Web 1.
- Frontal Web 2.
- Servidor de Base de Datos MySQL.

## 1.1 Fases de la práctica
Tendrá que resolver la práctica en diferentes fases, documentando en cada fase todos los pasos que ha ido realizando. El repositorio final tiene que contener un directorio para cada una de las fases donde se incluyan los scripts y archivos de configuración utilizados para su resolución.
```
práctica-wordpress-lamp
  .
  ├── fase00
  ├── fase01
  └── fase02
  ```
  
Las fases que tendrá que resolver son las siguientes:
- Fase 0. Instalación de Wordpress en un nivel (Un único servidor con todo lo necesario).
- Fase 1. Instalación de Wordpress en dos niveles (Servidor web, Servidor MySQL).
- Fase 2. Instalación de Wordpress en tres niveles (Balanceador, 2 Servidores webs, Servidor MySQL).

## 1.2 Tareas a realizar
A continuación se describen muy brevemente algunas de las tareas que tendrá que realizar sobre cada una de las máquinas.

### 1.2.1 Balanceador de carga
- Instalar el software necesario.
- Habilitar los módulos necesarios y configurar Apache HTTP Server como proxy inverso.

### 1.2.2 Front-End
- Instalar el software necesario.
- Descargar la última versión de WordPress y descomprimir en el directorio apropiado.
- Configurar WordPress para que pueda conectar con MySQL.
- Sincronizar el contenido estático en la capa de Front-End.
- Configurción de las Security Keys.

### 1.2.3 Back-End
- Instalar el software necesario.
- Configurar MySQL para que acepte conexiones que no sean de localhost.
- Crear una base de datos para WordPress.
- Crear un usuario para la base de datos de WordPress y asignarle los permisos apropiados.

## 1.3 Sincronización del contenido estático en la capa de Front-End
Al tener varias máquinas en la capa de Front-End tenemos que tener en cuenta que podemos tener algunos problemas a la hora de guardar contenido estático en el directorio uploads, instalar nuevos themes o instalar nuevos plugins, ya que estos contenidos se guardarán sobre el sistema de ficheros del frontal web que esté atendiendo nuestra petición. El contenido estático se almacena en el directorio wp-content.

Por ejemplo, puede ocurrir que hayamos instalado un nuevo plugin en uno de los frontales web y que el resto de frontales no tengan constancia de que este nuevo plugin ha sido instalado. También puede ocurrir que cuando uno de los frontales web esté fuera de servicio todo el contenido del directorio uploads estará inaccesible.

Para resolver este problema tenemos varias opciones, en nuestro caso vamos a estudiar las siguientes:
1. Utilizar almacenamiento compartido por NFS del directorio /var/www/html/wp-content entre todos los servidores de la capa de front-end.
2. Sincronización con rsync de los archivos del directorio /var/www/html/wp-content entre todos los servidores de la capa de front-end.
3. Utilizar un sistema de almacenamiento distribuido seguro con GlusterFS.

### 1.3.1 NFS
Podemos utilizar NFS para que los servidores de la capa de front-end compartan el directorio /var/www/html/wp-content. En nuestro caso un frontal hará de servidor NFS y el otro de cliente NFS. El servidor NFS compartirá el directorio /var/www/html/wp-content y el cliente podrá montar este directorio en su sistema de ficheros.

Por ejemplo, en mi caso las máquinas tendrán las siguientes IPs:
```
- Servidor NFS: 192.168.33.11
- Cliente NFS: 192.168.33.12
```

#### Paso 1: Instalación de paquetes
Instalación de paquetes necesarios en el servidor NFS:
```
sudo apt-get update
sudo apt-get install nfs-kernel-server
```
Instalación de paquetes necesarios en el cliente NFS:
```
sudo apt-get update
sudo apt-get install nfs-common
```

#### Paso 2: Exportamos el directorio en el servidor NFS
Cambiamos los permisos al directorio que vamos a compartir:
```
sudo chown nobody:nogroup /var/www/html/wp-content
```
Editamos el archivo /etc/exports:
```
sudo nano /etc/exports
```
Añadimos la siguiente línea:
```
/var/www/html/wp-content      192.168.33.12(rw,sync,no_root_squash,no_subtree_check)
```
Donde 192.168.33.12 es la IP del cliente NFS con el que queremos compartir el directorio.

#### Paso 3: Reiniciamos el servicio NFS
```
sudo /etc/init.d/nfs-kernel-server restart
```
**NOTA: Tenga en cuenta que para que el servicio de NFS pueda funcionar tendrá que abrir el puerto 2049 para poder aceptar conexiones TCP y UDP.**

#### 1.3.1.4 Paso 4: Creamos el punto de montaje en el cliente NFS
```
sudo mount 192.168.33.11:/var/www/html/wp-content /var/www/html/wp-content
```
Donde 192.168.33.11 es la IP del servidor NFS que está compartiendo el directorio.

Una vez hecho esto comprobamos con df -h que le punto de montaje aparece en el listado.
```
$ df -h

udev                                    490M     0  490M   0% /dev
tmpfs                                   100M  3.1M   97M   4% /run
/dev/sda1                               9.7G  1.1G  8.6G  12% /
tmpfs                                   497M     0  497M   0% /dev/shm
tmpfs                                   5.0M     0  5.0M   0% /run/lock
tmpfs                                   497M     0  497M   0% /sys/fs/cgroup
192.168.33.11:/var/www/html/wp-content  9.7G  1.1G  8.6G  12% /var/www/html/wp-content
tmpfs                                   100M     0  100M   0% /run/user/1000
```

#### 1.3.1.5 Paso 5: Editamos el archivo /etc/fstab en el cliente NFS
Editamos el archivo /etc/fstab para que al iniciar la máquina se monte automáticamente el directorio compartido por NFS.
```
sudo nano /etc/fstab
```
Añadimos la siguiente línea:
```
192.168.33.11:/var/www/html/wp-content /var/www/html/wp-content  nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
```
Donde 192.168.33.11 es la IP del servidor NFS que está compartiendo el directorio.

## 1.4 Notas sobre la configuración de Wordpress
### 1.4.1 Instalación sobre un directorio que no es el raíz
Si hemos realizado la instalación de WordPress sobre un directorio que no es el raíz tendremos que realizar dos pasos adicionales.

Por ejemplo, si tenemos los archivos de WordPress en el directorio `/var/www/html/wordpress` en lugar de tenerlos en el directorio `/var/www/html` tendremos que configurar la dirección de WordPress (`WP_SITEURL`) y la dirección del sitio (`WP_HOME`).

#### 1.4.1.1 Dirección de WordPress y Dirección del sitio
Una vez instalado WordPress accederemos al **panel de administración** y buscaremos la sección de **Ajustes -> Generales**. Allí configuraremos los valores de **Dirección de WordPress (`WP_SITEURL`)** y **Dirección del sitio (`WP_HOME`)** con los siguientes valores:

- **Dirección de WordPress (`WP_SITEURL`)**: http://IP_BALANCEADOR/wordpress
- **Dirección del sitio (`WP_HOME`)**: http://IP_BALANCEADOR

Ejemplo:
- **Dirección de WordPress (`WP_SITEURL`)**: http://192.168.33.10/wordpress
- **Dirección del sitio (`WP_HOME`)**: http://192.168.33.10

Nota:
- **Dirección de WordPress (`WP_SITEURL`)**: Es la URL que incluye el directorio donde está instalado WordPress.
- **Dirección del sitio (`WP_HOME`)**: Es la URL que queremos que usen los usuarios para acceder a WordPress.

### 1.4.2 Configuración de WordPress en un directorio que no es el raíz
Realiza las siguientes acciones en cada uno de los frontales web:
- Copia el archivo `/var/www/html/wordpress/index.php` a `/var/www/html/index.php`.
- Edita el archivo `/var/www/html/index.php` y modifica la siguiente línea de código:
```
/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wp-blog-header.php' );
```

Por esta línea de código:
```
/** Loads the WordPress Environment and Template */
require( dirname( __FILE__ ) . '/wordpress/wp-blog-header.php' );
```

Donde **`wordpress`** es el directorio donde se encuentra el código fuente de WordPress que hemos descomprimido en pasos anteriores.
```
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
```
Para que el contenido de los archivos .htaccess sea interpretado por el servidor web Apache tendrá que incluir la directiva AllowOverride en el archivo de configuración de Apache.

Una vez hecho esto ya podremos acceder a WordPress desde la IP del balanceador de carga.

### 1.4.3 Configuración de las *Security Keys*
Podemos mejorar la seguridad de WordPress configurando las security keys que aparecen en el archivo wp-config.php.

#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PROJECT_FOLDER="public_html"

PHP_INI=(
	"short_open_tag=On"
	"display_error=On"
	"display_startup_errors=On"
	"error_reporting=E_ALL \\\\& ~E_NOTICE \\\\& ~E_DEPRECATED \\\\& ~E_STRICT"
)

VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECT_FOLDER}"

    ErrorLog /var/www/html/vagrant-lamp/logs/error.log
    CustomLog /var/www/html/vagrant-lamp/logs/access.log combined

    <ifmodule mpm_itk_module>
        AssignUserID vagrant vagrant
    </ifmodule>

    Alias /phpinfo /var/www/phpinfo
    
    <Directory "/var/www/html/${PROJECT_FOLDER}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)

PHPINFO=$(cat <<EOF
<?php

phpinfo();

EOF
)


# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade


# install mysql and give password to installer
# ---------------------------------
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"


# install apache 2.5 and php 5.5
# ---------------------------------
sudo apt-get install -y apache2
sudo apt-get install -y apache2-mpm-itk
sudo apt-get install -y apache2-mpm-prefork
sudo apt-get install -y php5 
sudo apt-get install -y php5-curl
sudo apt-get install -y php5-gd
sudo apt-get install -y git
sudo apt-get install -y mysql-server
sudo apt-get install -y php5-mysql
sudo apt-get install -y build-essential
sudo apt-get install -y ruby1.9.1-dev
sudo apt-get install -y php-pear
sudo apt-get install -y php5-dev


# Set timezone
# ---------------------------------
echo "America/Sao_Paulo" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata


# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
# ---------------------------------
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password root"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password root"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password root"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin


# Apache changes
# ---------------------------------
rm -f /var/www/html/index.html
sudo mkdir /var/www/phpinfo
sudo mkdir "/var/www/html/${PROJECT_FOLDER}"
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf
echo "${PHPINFO}" > /var/www/phpinfo/index.php
echo "ServerName localhost" >> /etc/apache2/apache2.conf
sudo a2dismod mpm_prefork 
sudo a2enmod mpm_itk
sudo a2enmod rewrite


# Configure MySQL database and user
# ---------------------------------
echo "DROP DATABASE IF EXISTS devdb" | mysql -uroot -proot
echo "CREATE USER 'devdb'@'localhost' IDENTIFIED BY 'devdb'" | mysql -uroot -proot
echo "CREATE DATABASE devdb" | mysql -uroot -proot
echo "GRANT ALL ON devdb.* TO 'devdb'@'localhost'" | mysql -uroot -proot
echo "FLUSH PRIVILEGES" | mysql -uroot -proot
mysql -u root -proot devdb < /var/www/html/devdb.sql


# Install Composer
# ---------------------------------
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer


# Configure php.ini
# ---------------------------------
for ix in ${!PHP_INI[*]}
do
	IFS="=" read var val <<< ${PHP_INI[$ix]}
	PHP_CONF="$var = $val"
	sed -i "s#^$var.*#$PHP_CONF#" /etc/php5/apache2/php.ini
	echo "Set php.ini >>>> $var = $val"
done


# Install Mailcatcher
# ---------------------------------
echo "Installing mailcatcher"
sudo apt-get install -y libsqlite3-dev
sudo gem install mailcatcher --no-ri --no-rdoc
sed -i '/;sendmail_path =/c sendmail_path = "/usr/local/bin/catchmail"' /etc/php5/apache2/php.ini


# Restart serviços Apache & MySql
# ---------------------------------
sudo service apache2 restart
sudo service mysql restart

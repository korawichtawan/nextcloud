#!/bin/bash
sudo apt update -y
sudo apt install apache2 mariadb-server libapache2-mod-php7.4 -y
sudo apt install php7.4-gd php7.4-mysql php7.4-curl php7.4-mbstring php7.4-intl -y
sudo apt install php7.4-gmp php7.4-bcmath php-imagick php7.4-xml php7.4-zip unzip php -y
sudo wget https://download.nextcloud.com/server/releases/nextcloud-22.2.3.zip
sudo unzip nextcloud-22.2.3.zip -d /var/www/
sudo chown -R www-data:www-data /var/www/nextcloud/
sudo chmod -R 775 /var/www/nextcloud/ 
sudo echo 'Alias /nextcloud "/var/www/nextcloud/"

<Directory /var/www/nextcloud/>
  Require all granted
  AllowOverride All
  Options FollowSymLinks MultiViews

  <IfModule mod_dav.c>
    Dav off
  </IfModule>
</Directory>' > /etc/apache2/sites-available/nextcloud.conf
sudo echo "hello" > /var/www/html/index.html
sudo a2ensite nextcloud.conf
sudo a2enmod rewrite headers env dir mime setenvif ssl
sudo systemctl restart apache2

sudo touch /var/www/nextcloud/config/addon.config.php
sudo chmod 777 /var/www/nextcloud/config/addon.config.php
sudo echo "<?php
\$CONFIG =[
'skeletondirectory' => '',
'objectstore' => [
      'class' => '\\OC\\Files\\ObjectStore\\S3',
      'arguments' => [
              'bucket' => '${bucket_name}',
              'key'    => '${key}',
              'secret' => '${secret}',
              'use_ssl' => true,
              'use_path_style'=> true,
              'autocreate'=> true,
              'region'=> '${region}',
      ],
  ],
];" >> /var/www/nextcloud/config/addon.config.php
cd /var/www/nextcloud
sudo -u www-data php occ maintenance:install --database "mysql" --database-host "10.0.2.51" --database-name "${database_name}" --database-user "${database_user}" --database-pass "${database_pass}" --admin-user "${admin_user}" --admin-pass "${admin_pass}"          
sudo echo "${eip_ip}" > /var/www/html/index.html
sudo -u www-data php occ config:system:set trusted_domains 1 --value=${eip_ip}
sudo echo "${region}" > /var/www/html/index.html
sudo systemctl restart apache2

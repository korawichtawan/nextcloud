#!/bin/bash
sudo apt update -y
sudo apt install mariadb-server -y
sudo /etc/init.d/mysql start
sudo mysql -uroot -e "CREATE USER '${database_user}'@'%' IDENTIFIED BY '${database_pass}';CREATE DATABASE IF NOT EXISTS ${database_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;GRANT ALL PRIVILEGES ON ${database_name}.* TO '${database_user}'@'%';FLUSH PRIVILEGES;"
cd /etc/mysql/mariadb.conf.d/
sudo replace "127.0.0.1" "0.0.0.0" -- 50-server.cnf
sudo replace "#port" "port" -- 50-server.cnf
cd ~
sudo /etc/init.d/mysql restart

#!/bin/bash

#docker run -v docker start mysql
# docker run --name assetsecure-mysql -e MYSQL_ROOT_PASSWORD=my_crazy_super_secret_root_password -e MYSQL_DATABASE=assetsecure -e MYSQL_USER=assetsecure -e MYSQL_PASSWORD=whateverdood -d mysql
docker run -d assetsecure-mysql
#docker run -d -v ~/Projects/assetsecure/:/var/www/html -p $(boot2docker ip)::80   --link assetsecure-mysql:mysql --name=assetsecure assetsecure
docker run --link assetsecure-mysql:mysql -d -p 40000:80 --name=assetsecure -v ~/Projects/assetsecure/:/var/www/html \
-v ~/Projects/assetsecure-storage:/var/lib/assetsecure --env-file docker.env assetsecure-dev

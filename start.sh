#!/bin/bash
if [ ! -f /magento-db-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    MYSQL_PASSWORD=`pwgen -c -n -1 12`
    MAGENTO_DB_PASSWORD=`pwgen -c -n -1 12`
    MAGENTO_PASSWORD=`pwgen -c -n -1 12`
    echo "magento:$MAGENTO_PASSWORD" | chpasswd
    #This is so the passwords show up in logs.
    echo magento password: $MAGENTO_PASSWORD
    echo mysql root password: $MYSQL_PASSWORD
    echo mysql magento db password: $MAGENTO_DB_PASSWORD
    echo $MYSQL_PASSWORD > /mysql-root-pw.txt
    echo $MAGENTO_DB_PASSWORD > /magento-db-pw.txt
    echo $MAGENTO_PASSWORD > /magento-pw.txt

    mysqladmin -u root password $MYSQL_PASSWORD
    mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE magento; GRANT ALL PRIVILEGES ON magento.* TO 'magento'@'localhost' IDENTIFIED BY '$MAGENTO_DB_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld
fi

if [ ! -f /home/magento/files/html/nginx.conf.sample ]; then
    MAGENTO_DB="magento"
    MAGENTO_PASSWORD=`cat /magento-db-pw.txt`
    touch /home/magento/files/html/nginx.conf.sample
    chown -R magento: /home/magento/files/html/
fi

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
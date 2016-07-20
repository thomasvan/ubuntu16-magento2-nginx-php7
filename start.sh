#!/bin/bash
if [ ! -f /magento-db-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    MYSQL_PASSWORD=`pwgen -c -n -1 12`
    MAGENTO_PASSWORD=`pwgen -c -n -1 12`
    #This is so the passwords show up in logs.
    echo mysql root password: $MYSQL_PASSWORD
    echo magento password: $MAGENTO_PASSWORD
    echo $MYSQL_PASSWORD > /mysql-root-pw.txt
    echo $MAGENTO_PASSWORD > /magento-db-pw.txt

    mysqladmin -u root password $MYSQL_PASSWORD
    mysql -uroot -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$MYSQL_PASSWORD -e "CREATE DATABASE magento; GRANT ALL PRIVILEGES ON magento.* TO 'magento'@'localhost' IDENTIFIED BY '$MAGENTO_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld
fi

if [ ! -f /usr/share/nginx/www/composer.json ]; then
    MAGENTO_DB="magento"
    MAGENTO_PASSWORD=`cat /magento-db-pw.txt`

    chown -R magento: /usr/share/nginx/www/

fi

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
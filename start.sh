#!/bin/bash
if [ ! -f /magento-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    ROOT_PASSWORD=`pwgen -c -n -1 12`
    MYSQL_ROOT_PASSWORD="root"
    MYSQL_MAGENTO_PASSWORD="magento"
    MAGENTO_PASSWORD="magento"
    # echo "magento:$MAGENTO_PASSWORD" | chpasswd
    echo "root:$ROOT_PASSWORD" | chpasswd

    #This is so the passwords show up in logs.
    echo root password: $ROOT_PASSWORD
    echo magento password: $MAGENTO_PASSWORD
    echo mysql root password: $MYSQL_ROOT_PASSWORD
    echo mysql magento password: $MYSQL_MAGENTO_PASSWORD
    echo $ROOT_PASSWORD > /root-pw.txt
    echo $MAGENTO_PASSWORD > /magento-pw.txt
    echo $MYSQL_ROOT_PASSWORD > /mysql-root-pw.txt
    echo $MYSQL_MAGENTO_PASSWORD > /mysql-magento-pw.txt

    mysqladmin -u root password $MYSQL_ROOT_PASSWORD
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE magento; GRANT ALL PRIVILEGES ON magento.* TO 'magento'@'localhost' IDENTIFIED BY '$MYSQL_MAGENTO_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld
    mv /var/lib/mysql/ibdata1 /var/lib/mysql/ibdata1.bak
    cp -a /var/lib/mysql/ibdata1.bak /var/lib/mysql/ibdata1
fi

if [ ! -f /home/magento/files/html/nginx.conf.sample ]; then
    MAGENTO_DB="magento"
    MAGENTO_PASSWORD=`cat /magento-pw.txt`
    touch /home/magento/files/html/nginx.conf.sample
    chown -R magento: /home/magento/files/html/
else
    yes | cp -R /home/magento/files/html/vendor/magento/module-solr/conf/* /opt/solr/example/solr/collection1/conf/
    sed -i 's/solr\.data\.dir:\.\/solr\/data/solr\.data\.dir:/g' /opt/solr/example/solr/collection1/conf/solrconfig.xml
fi

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
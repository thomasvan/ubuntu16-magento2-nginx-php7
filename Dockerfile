FROM ubuntu:18.04
MAINTAINER Thomas Van<thomas@forixdigital.com>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl && \
    ln -sf /bin/true /sbin/initctl && \
    mkdir /var/run/sshd && \
    mkdir /run/php && \
    mkdir /var/run/mysqld

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y software-properties-common && \
    LC_ALL=C.UTF-8 add-apt-repository -y -u ppa:ondrej/php


# Basic Requirements
RUN apt-get -y install python-setuptools curl git nano sudo unzip openssh-server openssl shellinabox
RUN apt-get -y install mysql-server php7.0-fpm

# Magento Requirements
RUN apt-get -y install php7.0-xml php7.0-mcrypt php7.0-mbstring php7.0-bcmath php7.0-gd php7.0-zip php7.0-mysql php7.0-curl php7.0-intl php7.0-soap php7.0-xdebug

# MySQL config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# nginx config
RUN apt-get -y install nginx && \
    sed -i -e"s/user\s*www-data;/user magento www-data;/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN phpdismod opcache xdebug && \
    sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 2048M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 3600/g" /etc/php/7.0/fpm/php.ini /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/;\s*max_input_vars\s*=\s*1000/max_input_vars = 36000/g" /etc/php/7.0/fpm/php.ini /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/user\s*=\s*www-data/user = magento/g" /etc/php/7.0/fpm/pool.d/www.conf
ADD conf/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

# nginx site conf
ADD conf/nginx-site.conf /etc/nginx/sites-available/default
RUN mkdir /etc/nginx/magento-conf.d
ADD conf/nginx-magento.conf /etc/nginx/magento-conf.d

# Generate self-signed ssl cert
RUN mkdir /etc/nginx/ssl/
RUN openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" \
    -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
    -out /etc/ssl/certs/ssl-cert-snakeoil.pem

# Install composer and modman
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    curl -sSL https://raw.github.com/colinmollenhour/modman/master/modman > /usr/sbin/modman && \
    chmod +x /usr/sbin/modman

# Supervisor Config
RUN apt-get install -y supervisor
ADD conf/supervisord.conf /etc/supervisord.conf

# Add system user for Magento
RUN useradd -m -d /home/magento -p $(openssl passwd -1 'magento') -G root -s /bin/bash magento \
    && usermod -a -G www-data magento \
    && usermod -a -G sudo magento \
    && mkdir -p /home/magento/files/html \
    && chown -R magento: /home/magento/files \
    && chmod -R 775 /home/magento/files

# Generate private/public key for "magento" user
RUN sudo -H -u magento bash -c 'echo -e "\n\n\n" | ssh-keygen -t rsa'

# Elastic Search
# RUN apt-get update && \
RUN apt-get -y install openjdk-8-jre && \
    useradd elasticsearch && \
    curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.4.tar.gz && \
    tar -zxf elasticsearch-5.6.4.tar.gz && \
    mv elasticsearch-5.6.4 /etc/ && \
    mkdir /etc/elasticsearch-5.6.4/logs && \
    touch /etc/elasticsearch-5.6.4/logs/elastic4magento.log && \
    curl -L -O https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-2.4.6.tar.gz && \
    tar -zxf elasticsearch-2.4.6.tar.gz && \
    mv elasticsearch-2.4.6 /etc/ && \
    mkdir /etc/elasticsearch-2.4.6/logs && \
    touch /etc/elasticsearch-2.4.6/logs/elastic4magento.log && \
    chown -R elasticsearch /etc/elasticsearch-* && \
    rm -f elasticsearch-*

RUN echo "cluster.name: elastic4magento\nnode.name: node-5.x\nnode.master: true\nnode.data: true\ntransport.host: localhost\ntransport.tcp.port: 9302\nhttp.port: 9202\nnetwork.host: 0.0.0.0\nindices.query.bool.max_clause_count: 16384" >> /etc/elasticsearch-5.6.4/config/elasticsearch.yml
RUN echo "cluster.name: elastic4magento\nnode.name: node-2.x\n#node.master: true\nnode.data: true\ntransport.host: localhost\ntransport.tcp.port: 9300\nhttp.port: 9200\nnetwork.host: 0.0.0.0\nindices.query.bool.max_clause_count: 16384" >> /etc/elasticsearch-2.4.6/config/elasticsearch.yml

# Redis Server
RUN apt-get -y install redis-server && \
    sed -i "s/daemonize\s*yes/daemonize no/g" /etc/redis/redis.conf && \
    sed -i "s/^bind.*$/bind 0.0.0.0/g" /etc/redis/redis.conf && \
    sed -i "s/databases\s*16/databases 4/g" /etc/redis/redis.conf && \
    echo "maxmemory 1G" >> /etc/redis/redis.conf

# phpMyAdmin
RUN curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - && \
    mv phpMyAdmin* /usr/share/phpmyadmin
ADD conf/config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN chown -R magento: /usr/share/phpmyadmin

# Magento cron and startup Script
COPY conf/magento.cron /tmp/
ADD ./start.sh /start.sh

RUN crontab -u magento /tmp/magento.cron && \
    chmod 755 /start.sh && \
    chown mysql:mysql /var/run/mysqld

#NETWORK PORTS
# private expose
EXPOSE 9202
EXPOSE 9200
EXPOSE 9011
EXPOSE 9000
EXPOSE 6379
EXPOSE 4200
EXPOSE 3306
EXPOSE 443
EXPOSE 80
EXPOSE 22

# volume for mysql database and magento install
VOLUME ["/var/lib/mysql", "/home/magento/files"]
CMD ["/bin/bash", "/start.sh"]

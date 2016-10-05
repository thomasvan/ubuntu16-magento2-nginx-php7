FROM ubuntu:16.04
MAINTAINER Thomas Van<thomas@forixwebdesign.com>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN mkdir /var/run/sshd
RUN mkdir /run/php

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y upgrade

# Basic Requirements
RUN apt-get -y install pwgen python-setuptools curl git nano sudo unzip openssh-server openssl
RUN apt-get -y install mysql-server nginx php-fpm php-mysql

# Magento Requirements

RUN apt-get -y install php-imagick php-intl php-curl php-xsl php-mcrypt php-mbstring php-bcmath php-gd php-zip
# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# nginx config
RUN sed -i -e"s/user\s*www-data;/user magento www-data;/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/user\s*=\s*www-data/user = magento/g" /etc/php/7.0/fpm/pool.d/www.conf
# replace # by ; RUN find /etc/php/7.0/mods-available/tmp -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# nginx site conf
ADD ./nginx-site.conf /etc/nginx/sites-available/default

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
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN curl -sSL https://raw.github.com/colinmollenhour/modman/master/modman > /usr/sbin/modman
RUN chmod +x /usr/sbin/modman

# Supervisor Config
RUN /usr/bin/easy_install supervisor
RUN /usr/bin/easy_install supervisor-stdout
ADD ./supervisord.conf /etc/supervisord.conf

# Add system user for Magento
RUN useradd -m -d /home/magento -p $(openssl passwd -1 'magento') -G root -s /bin/bash magento \
    && usermod -a -G www-data magento \
    && usermod -a -G sudo magento \
    && mkdir -p /home/magento/files/html \
    && chown -R magento:www-data /home/magento/files \
    && chmod -R 775 /home/magento/files

# Install elasticsearch
RUN apt-get -y install openjdk-8-jdk
RUN wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee -a /etc/apt/sources.list.d/Elasticsearch-2.x.list
RUN apt-get -y update && apt-get -y install elasticsearch

# Install SOLR
RUN curl --retry 3 https://archive.apache.org/dist/lucene/solr/4.9.1/solr-4.9.1.tgz | tar -C /opt --extract --gzip
RUN mv /opt/solr-4.9.1 /opt/solr
RUN useradd --home-dir /opt/solr --comment "Solr Server" solr
RUN chown -R solr:solr /opt/solr/example

# Magento Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

#NETWORK PORTS
# private expose
EXPOSE 9011
EXPOSE 8983
EXPOSE 3306
EXPOSE 443
EXPOSE 80
EXPOSE 22

# volume for mysql database and magento install
VOLUME ["/var/lib/mysql", "/home/magento/files", "/var/run/sshd"]

CMD ["/bin/bash", "/start.sh"]
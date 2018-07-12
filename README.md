# ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more

Run the latest magento 2 on Ubuntu 16.04.4 LTS, including: 
- Shell In A Box – A Web-Based SSH Terminal - version 2.19
- nginx/1.10.3 (Ubuntu)
- php-fpm 7.1
- elasticsearch 5.6.4 and 2.4.6
- redis server version 3.0.6 
- mysql version 14.14 Distrib 5.7.22, for Linux (x86_64) 
- You can also handle all services using supervisord <container_ip>:9011 or commandline: 
```bash
magento@c9786d14b245:~/files/html$ sudo supervisorctl 
BroswerBased-SSH                 RUNNING   pid 421, uptime 3:36:05
ElasticSearch_2.x_9200           STOPPED   Not started
ElasticSearch_5.x_9202           RUNNING   pid 420, uptime 3:36:05
MySQL                            RUNNING   pid 1437, uptime 3:35:01
NGINX                            RUNNING   pid 2329, uptime 1:21:16
PHP-FPM                          RUNNING   pid 417, uptime 3:36:05
RedisServer                      RUNNING   pid 2256, uptime 2:57:26
System-Log                       RUNNING   pid 422, uptime 3:36:05
```
###Todo:

1. If anyone has suggestions please leave a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more/issues/2).
2. Implement [Docker Compose](https://docs.docker.com/compose/) for a quicker setup.
3. Clean up README.
4. Requests? Just make a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more/issues/1) if there's anything you'd like added or changed.

## Installation

The easiest way get up and running with this docker container is to pull the latest stable version from the [Docker Hub Registry](https://hub.docker.com/r/thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more/):

```bash
$ docker pull thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more:latest
```

If you'd like to build the image yourself:

```bash
$ git clone https://github.com/thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more.git
$ cd ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more
$ docker build -t="thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more" .
```

## Usage


Services and port exposed
- Shell In A Box – A Web-Based SSH Terminal 2.19 - http://<contaner_ip>:4200
- ElasticSearch 5.6.4 - <contaner_ip>:9002
- ElasticSearch 2.4.6 - <contaner_ip>:9000
- MySQL 5.7.22 - <contaner_ip>:3306
- Nginx 1.10.3 and php-fpm 7.1 - http://<contaner_ip> and https://<contaner_ip> for web browsing

Sample container initialization: 
```bash
$ docker run -v <your-webapp-root-directory>:/home/magento/files/html -p 2222:4200 -p 9011:9011 --name docker-name -d thomasvan/ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more:latest
```

Start your newly created container, named *docker-name*.

```bash
$ docker start docker-name
```

After starting the container ubuntu16-magento2-nginx-php7.1-2xelasticsearch-redis-and-more, please check to see if it has started and the port mapping is correct. This will also report the port mapping between the docker container and the host machine.

```
$ docker ps

0.0.0.0:9011->9011/tcp, 0.0.0.0:2222->4200/tcp
```

You can then visit the following URL in a browser on your host machine to get started(account: magento/magento):

```
http://127.0.0.1:2222
```

You can start/stop/restart and view the error logs of nginx and php-fpm services:
```
http://127.0.0.1:9011
```

And this is the most important part, get the container ip and other information to setup magento there, you could get those by: 
- Looking into the output as `docker run ...`command run or `docker logs <container-id>`:
- Using [docker inspect](https://docs.docker.com/engine/reference/commandline/inspect/parent-command) command
- Check the ~/readme.txt file by using [Web-Based SSH Terminal](http://127.0.0.1:2222)

```
c9786d14b245 login: magento
Password:
Last login: Thu Jul 12 06:21:00 UTC 2018 from 172.17.0.1 on pts/1
Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.15.0-26-generic x86_64)

 * Documentation: https://help.ubuntu.com
 * Management: https://landscape.canonical.com
 * Support: https://ubuntu.com/advantage
magento@c9786d14b245:~$ cat ~/readme.txt
IP Address : 172.17.0.2
Web Directory : /home/magento/files/html
SSH/SFTP User : magento/magento
ROOT User : root/root
Database Host : localhost
Database Name : magento
Database User : magento/magento
DB ROOT User : root/root 
```

Now as you've got all that information, you can set up magento and access the website via IP Address or creating an alias in [hosts](https://support.rackspace.com/how-to/modify-your-hosts-file/) file
```
c9786d14b245 login: magento
Password:
Last login: Thu Jul 12 08:50:07 UTC 2018 from 172.17.0.1 on pts/2
Welcome to Ubuntu 16.04.4 LTS (GNU/Linux 4.15.0-26-generic x86_64)

* Documentation: https://help.ubuntu.com
* Management: https://landscape.canonical.com
* Support: https://ubuntu.com/advantage
magento@c9786d14b245:~$ cd files/html/
magento@c9786d14b245:~/files/html$ echo "install magento 2 here..."
install magento 2 here...
magento@c9786d14b245:~/files/html$ echo "all set, you can browse your website now"
all set, you can browse your website now
magento@c9786d14b245:~/files/html$
   ```

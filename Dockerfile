FROM ubuntu:16.04
MAINTAINER Viet Duong<viet.duong@hotmail.com>

# Compatible with :
#    Ubuntu 16.04
#    Nginx 1.15.x
#    MySQL 14.14
#    PHP 7.0

# Set one or more individual labels
LABEL vietcli.docker.base.image.version="0.1.0-beta"
LABEL vendor="[VietCLI] vietduong/lemp-image"
LABEL vietcli.docker.base.image.release-date="2018-08-08"
LABEL vietcli.docker.base.image.version.is-production=""

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN mkdir /var/run/sshd
RUN mkdir /run/php

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

# Custom Environment Variables
ENV HTTP_SERVER_NAME magento2.local

# Update apt-get
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 \
    && echo 'deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx' >> /etc/apt/sources.list.d/nginx.list \
    && apt-get update \
    && apt-get install locales \
    && locale-gen en_US.UTF-8 \
    && export LANG=en_US.UTF-8 \
    && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update \
    && apt-get -y upgrade

# Basic Requirements
RUN apt-get update
RUN apt-get -y install pwgen python-setuptools curl git nano sudo unzip openssh-server openssl
RUN apt-get -y install nginx=1.15.* php7.0-fpm php7.0-mysql

# Install imagemagick
RUN apt-get -y install imagemagick

# Magento 2 Requirements
RUN apt-get -y install php7.0-imagick php7.0-intl php7.0-curl php7.0-xsl php7.0-mcrypt php7.0-mbstring php7.0-bcmath php7.0-gd php7.0-zip php7.0-soap

# nginx config
RUN sed -i -e"s/user\s*nginx;/user vietcli;/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN sed -i -e"s/include\s*\/etc\/nginx\/conf.d\/\*.conf;/include \/etc\/nginx\/conf.d\/\*.conf;\n\tinclude \/etc\/nginx\/sites-enabled\/\*;/" /etc/nginx/nginx.conf
#RUN sed -i "61i \\\troot /home/vietcli/files/html;" /etc/nginx/nginx.conf
#RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;always_populate_raw_post_data\s*=\s*-1/always_populate_raw_post_data = -1/g" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/user\s*=\s*www-data/user = vietcli/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/group\s*=\s*www-data/group = vietcli/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/listen.owner\s*=\s*www-data/listen.owner = vietcli/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN sed -i -e "s/listen.group\s*=\s*www-data/listen.group = vietcli/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN echo "php_admin_flag[log_errors] = on" >> /etc/php/7.0/fpm/pool.d/www.conf
RUN echo "php_admin_value[memory_limit] = 2048" >> /etc/php/7.0/fpm/pool.d/www.conf
RUN echo "php_admin_value[max_execution_time] = 3600" >> /etc/php/7.0/fpm/pool.d/www.conf
RUN echo "php_admin_value[max_input_vars] = 36000" >> /etc/php/7.0/fpm/pool.d/www.conf
RUN echo "php_admin_value[post_max_size] = 20M" >> /etc/php/7.0/fpm/pool.d/www.conf
RUN echo "php_admin_value[upload_max_filesize] = 20M" >> /etc/php/7.0/fpm/pool.d/www.conf

# nginx site conf
ADD ./nginx.default.conf /etc/nginx/conf.d/default.conf
# mysql installation


#The following commands set the MySQL root password to 'vietcli' when you install the mysql-server package.
RUN echo "mysql-server mysql-server/root_password password" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password" | debconf-set-selections && \
    apt install -y mysql-server

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
#RUN mysql -uroot -p'vietcli' -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'vietcli' WITH GRANT OPTION; FLUSH PRIVILEGES;"

# PHPMyAdmin
#RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
#RUN echo 'phpmyadmin phpmyadmin/app-password-confirm password phpmyadmin_password ' | debconf-set-selections
#RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password mysql_pass' | debconf-set-selections
#RUN echo 'phpmyadmin phpmyadmin/mysql/app-pass password mysql_pass' | debconf-set-selections
#RUN echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
#RUN /etc/init.d/mysql start; apt-get -y install phpmyadmin --no-install-recommends

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

# Install phpmyadmin
#RUN apt-get install phpmyadmin -y

# Install Ioncube
#RUN wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
# && tar xvfz ioncube_loaders_lin_x86-64.tar.gz \
# && PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
# && PHP_EXT_DIR=$(php -i | grep extension_dir | tr -s ' ' | cut -d ' ' -f 5) \
## && PHP_EXT_DIR=$(php-config --extension-dir) \
# && mkdir -p $PHP_EXT_DIR \
# && cp "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" $PHP_EXT_DIR \
# && cp "ioncube/ioncube_loader_lin_${PHP_VERSION}_ts.so" $PHP_EXT_DIR \
#&& rm -rf ioncube ioncube_loaders_lin_x86-64.tar.gz \
#&& sed -i "925i \ \ " /etc/php/$PHP_VERSION/fpm/php.ini \
#&& sed -i "925i zend_extension = ${PHP_EXT_DIR}/ioncube_loader_lin_${PHP_VERSION}.so" /etc/php/$PHP_VERSION/fpm/php.ini \
#&& sed -i "925i \ \ " /etc/php/${PHP_VERSION}/cli/php.ini \
#&& sed -i "925i zend_extension = ${PHP_EXT_DIR}/ioncube_loader_lin_${PHP_VERSION}.so" /etc/php/$PHP_VERSION/cli/php.ini

# Reload PHP Configurations

RUN service php7.0-fpm restart

# Add system user for Magento
RUN useradd -m -d /home/vietcli -p $(openssl passwd -1 'vietcli') -G root -s /bin/bash vietcli \
    && usermod -a -G www-data vietcli \
    && usermod -a -G sudo vietcli \
    && mkdir -p /home/vietcli/files/html \
    && chown -R vietcli:www-data /home/vietcli/files \
    && chmod -R 775 /home/vietcli/files

# Magento Initialization and Startup Script
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

#NETWORK PORTS
# MySQL Server Port
EXPOSE 3306

# SSL Port
EXPOSE 443

# HTTP Port
EXPOSE 80

# SSH Port
EXPOSE 22

# volume for mysql database and magento install
VOLUME ["/home/vietcli/files", "/home/vietcli/.log", "/var/run/sshd"]

CMD ["/bin/bash", "/start.sh"]
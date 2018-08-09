#!/bin/bash
if [ ! -f /home/vietcli/.log/vietcli-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
    ROOT_PASSWORD=`pwgen -c -n -1 12`
    VIETCLI_PASSWORD="vietcli"

    # echo "vietcli:$MAGENTO_PASSWORD" | chpasswd
    echo "root:$ROOT_PASSWORD" | chpasswd

    #This is so the passwords show up in logs.
    mkdir /home/vietcli/.log
    echo root password: $ROOT_PASSWORD
    echo vietcli password: $VIETCLI_PASSWORD

    echo $ROOT_PASSWORD > /home/vietcli/.log/root-pw.txt
    echo $VIETCLI_PASSWORD > /home/vietcli/.log/vietcli-pw.txt

    # Enable Magento 2 site
    if [ ! -d "/etc/nginx/sites-enabled/" ]; then
        mkdir /etc/nginx/sites-enabled;
    fi

    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

fi


if [ ! -f /home/vietcli/.log/mysql-vietcli-root-pw.txt ]; then
    #mysql has to be started this way as it doesn't work to call from /etc/init.d
    /usr/bin/mysqld_safe &
    sleep 10s
    # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php

    MYSQL_ROOT_PASSWORD=`pwgen -c -n -1 12`
    MYSQL_VIETCLI_PASSWORD="vietcli"

    #This is so the passwords show up in logs.
    echo mysql root password: $MYSQL_ROOT_PASSWORD
    echo mysql vietcli password: $MYSQL_VIETCLI_PASSWORD

    echo $MYSQL_ROOT_PASSWORD > /home/vietcli/.log/mysql-vietcli-root-pw.txt
    echo $MYSQL_VIETCLI_PASSWORD > /home/vietcli/.log/mysql-vietcli-pw.txt

    mysqladmin -u root -pvietcli password $MYSQL_ROOT_PASSWORD
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE vietcli_db; GRANT ALL PRIVILEGES ON vietcli_db.* TO 'vietcli'@'localhost' IDENTIFIED BY '$MYSQL_VIETCLI_PASSWORD'; FLUSH PRIVILEGES;"
    killall mysqld

    service mysql restart
fi


# Set default index for magento 2 project
if [ ! -f /home/vietcli/files/html/pub/index.php ]; then
    mkdir /home/vietcli/files/html/pub
    echo "<h1>Vietcli Default Page For Magento 2 Project</h1>" > /home/vietcli/files/html/pub/index.php
fi

#Starting up
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && service mysql start
service nginx restart
service php7.0-fpm restart

# run SSH
/usr/sbin/sshd -D
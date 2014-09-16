#!/usr/bin/env bash

# Ensures if the specified file is present and the md5 checksum is equal
ensureFilePresentMd5 () {
    source=$1
    target=$2
    if [ "$3" != "" ]; then description=" $3"; else description=" $source"; fi
 
    md5source=`md5sum ${source} | awk '{ print $1 }'`
    if [ -f "$target" ]; then md5target=`md5sum $target | awk '{ print $1 }'`; else md5target=""; fi

    if [ "$md5source" != "$md5target" ];
    then
        echo "Provisioning $description file to $target..."
        cp $source $target
        echo "...done"
        return 1
    else
        return 0
    fi
}

provision() {
  
  #Make CentOS confirm with some of the work we use elsewhere
  wget http://packages.sw.be/rpmforge-release/rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
  sudo rpm -i rpmforge-release-0.5.2-2.el5.rf.x86_64.rpm
  sudo yum install -y apt
  
  #install nano
  sudo yum install -y nano
 
  #Apache
  apt-get update
  sudo yum install -y httpd
  
#TO-DO Figure out what PHP modules exist
  # Apache conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/httpd.conf /etc/httpd/httpd.conf "custom httpd settings"
  
  #MySQL
  sudo yum install -y mysql-server
#TO-DO Figure out what PHP modules exist
  # MySQL conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/my.cnf /etc/my.cnf "custom mysql settings"
  sudo /etc/init.d/mysqld start
  
  #PHP
  #We need to install these to get to 5.3.*
  sudo rpm -Uvh http://mirror.webtatic.com/yum/centos/5/latest.rpm
  sudo yum --enablerepo=webtatic install php
  sudo yum install -y php-mysql
  
#TO-DO Figure out what PHP modules exist 
#   apt-get install -y php5 libapache2-mod-php5 php5-mcrypt
#   apt-get install -y php5-curl
#   apt-get install -y php5-gd
#   apt-get install -y php5-mysql
#   apt-get install -y php5-xmlrpc
#   apt-get install -y php5-tidy
#   apt-get install -y php5-mcrypt
#   apt-get install -y php5-xdebug
#   apt-get install -y php5-xhprof
#   apt-get install -y php5-json

#TO-DO Figure out what PHP modules exist
  # PHP conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/php.ini /etc/php.ini "custom php settings"

  
  #GIT
  sudo yum install -y git

  #Drush
  sudo yum install -y php-pear
  sudo pear channel-discover pear.drush.org
  sudo pear install drush/drush
#sudo drush version

  #Fixes Permissions Issue
  sudo rm -Rf /var/www
  sudo ln -fs /vagrant /var/www
  sudo chown -Rf vagrant:vagrant /var/www/
  sudo chmod 0755 /var/www/html/
  sudo chmod 0755 /vagrant/html/
  
  #restart Apache/PHP
  echo "Restarting Apache/PHP..."; sudo /etc/init.d/httpd restart; echo "...done";
  
}

provision
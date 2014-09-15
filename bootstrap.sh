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
  #Apache
  apt-get update
  apt-get install -y apache2
  rm -rf /var/www
  ln -fs /vagrant /var/www

  # Apache conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/apache2.conf /etc/apache2/apache2.conf "custom httpd settings"
  ensureFilePresentMd5 /vagrant/projectProvision/envvars /etc/apache2/envvars "custom httpd settings"

  #MySQL
  apt-get install debconf-utils -y
  #One of these pairs worked. All three pairs are not needed. Figure out which one works and remove the others
  debconf-set-selections <<< "mysql-server-5.5 mysql-server-5.5/root_password password pass"
  debconf-set-selections <<< "mysql-server-5.5 mysql-server-5.5/root_password_again password pass"
  debconf-set-selections <<< "mysql-server mysql-server/root_password password pass"
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password pass"
  debconf-set-selections <<< "mysql-server mysql-server-5.5/root_password password pass"
  debconf-set-selections <<< "mysql-server mysql-server-5.5/root_password_again password pass"
  sudo apt-get install -y mysql-server-5.5 libapache2-mod-auth-mysql

  #PHP
  apt-get install -y php5 libapache2-mod-php5 php5-mcrypt
  apt-get install -y php5-curl
  apt-get install -y php5-gd
  apt-get install -y php5-mysql
  apt-get install -y php5-xmlrpc
  apt-get install -y php5-tidy
  #apt-get install php5-sqlite
  apt-get install -y php5-mcrypt
  apt-get install -y php5-xdebug
  apt-get install -y php5-xhprof
  apt-get install -y php5-json

  # PHP conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/php.ini /etc/php5/apache2/php.ini "custom php settings"

  #restart Apache/PHP
  echo "Restarting Apache/PHP..."; sudo service apache2 restart; echo "...done";

  #GIT
  sudo apt-get install -y git

  #Drush
  sudo apt-get install -y php-pear
  sudo pear channel-discover pear.drush.org
  sudo pear install drush/drush
  sudo drush version

  #Fixes Permissions Issue
  sudo chmod 0755 /var/www/html/
  sudo chmod 0755 /vagrant/html/
}

provision
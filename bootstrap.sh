#!/usr/bin/env bash

#Variables loaded via YAML in the vagrantfile are passed as:
# $1 = hostname
# $2 = ip
# $2 = dbHost
# $4 = dbName
# $5 = dbUser
# $6 = dbPass

# Ensures if the specified file is present and the md5 checksum is equal
ensureFilePresentMd5 () {
    source=$1
    target=$2
    if [ "$4" != "" ]; then description=" $4"; else description=" $source"; fi
 
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
  sudo yum install -y httpd
  #Apache install mod_ssl
  yum install -y mod_ssl
  # Apache conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/httpd.conf /etc/httpd/conf/httpd.conf "custom httpd settings"
  
  #MySQL
  sudo yum install -y mysql-server
  # MySQL conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/my.cnf /etc/my.cnf "custom mysql settings"
  sudo /etc/init.d/mysqld start  
  #If the mysqlImport file was configured, set up the db and import it. 
  if [ -f /vagrant/mysqlImport.sql ]
    then
      #create the project's db
      mysql -u root -h $3 -Bse "CREATE DATABASE $4;"
      echo "Database $4 Created";
      #grant access
      if [ "$6" = "" ]
        then
          mysql -u root -h $3 -Bse "GRANT ALL ON $4.* to $5@'%';"
          #import the db. 
          mysql -u $5 $4 < /vagrant/mysqlImport.sql
          echo "Database imported - sql user password not used";
        else
          mysql -u root -h $3 -Bse "GRANT ALL ON $4.* to $5@'%' IDENTIFIED BY '$6';"
          mysql -u $5 -p$6 $4 < /vagrant/mysqlImport.sql
          echo "Database imported - sql user password was used";
      fi
      echo "Database: User $5 granted access to db and a password was set"; 
    else
      echo "Database Creation Skipped because the mysqlImport.sql file was not configured.";
  fi
    
  #PHP
  #First remove old versions
  sudo yum remove -y php-pear-1.4.9-8.el5
  #We need to install these to get to 5.3.*
  sudo rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
  sudo yum install -y php53
  sudo yum install -y php53-mysql
  sudo yum install -y php53-bcmath
  sudo yum install -y php53-gd
  sudo yum install -y php53-imap
  sudo yum install -y php53-mbstring
  sudo yum install -y php53-soap
  sudo yum install -y php53-xml
  sudo yum install -y php53-mcrypt
  sudo yum install -y php53-process
  # PHP Modules
  for file in /vagrant/projectProvision/phpModules/*
    do
      filename="$(basename "$file")"
      ensureFilePresentMd5 "$file" /usr/lib64/php/modules/$filename "php modules"
  done
  # PHP conf overrides
  ensureFilePresentMd5 /vagrant/projectProvision/php.ini /etc/php.ini "custom php settings"
    
  #MySQL and httpd don't start on boot by default, Fix this
  sudo /sbin/chkconfig --level 345 httpd on
  sudo /sbin/chkconfig --level 345 mysqld on
  
  #GIT
  sudo yum install -y git

  #Drush
  sudo yum install -y php-pear
  sudo pear channel-discover pear.drush.org
  sudo pear install drush/drush

  #Fixes Permissions Issue
  sudo rm -Rf /var/www
  sudo ln -fs /vagrant /var/www
  sudo chown -Rf vagrant:vagrant /var/www/
  sudo chmod 0755 /var/www/html/
  sudo chmod 0755 /vagrant/html/
  
  #restart Apache/PHP
  echo "Restarting Apache/PHP..."; sudo /etc/init.d/httpd restart; echo "...done";
  
}

provision $1 $2 $3 $4 $5 $6
#!/bin/bash
###zabbix upgrade###
# update  dbversion set mandatory = '4000000' where optional = '5000004';
#vars
distro=$1
systemc stop zabbix-server
#create backup before upgrade
bckp () {
 mkdir -p /opt/zabbix_backup/bin_files /opt/zabbix_backup/conf_files /opt/zabbix_backup/doc_files

 mkdir -p /opt/zabbix_backup/web_files /opt/zabbix_backup/db_files

 cp -rp /etc/zabbix/zabbix_server.conf /opt/zabbix_backup/conf_files 
 cp -rp /usr/sbin/zabbix_server /opt/zabbix_backup/bin_files 
 cp -rp /usr/share/doc/zabbix-* /opt/zabbix_backup/doc_files 
 cp -rp /etc/httpd/conf.d/zabbix.conf /opt/zabbix_backup/conf_files 2>/dev/null
 cp -rp /etc/apache2/conf-enabled/zabbix.conf /opt/zabbix_backup/conf_files 2>/dev/null 
 cp -rp /etc/zabbix/php-fpm.conf /opt/zabbix_backup/conf_files 2>/dev/null
 cp -rp /usr/share/zabbix/ /opt/zabbix_backup/web_files
}
if ( systemctl status mysqld ); then
   #dump DB
     mysqldump -h localhost -u'root' -p'Tiger@1234' --single-transaction 'zabbix' | gzip > /opt/zabbix_backup/db_files/zabbix_backup.sql.gz
 else
   echo "Use CTRL + C to stop and check"
   read
 fi

case $distro in
 -rhel)
bckp 
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/$(rpm -E %{rhel})/x86_64/zabbix-release-5.0-1.el$(rpm -E %{rhel}).noarch.rpm
yum clean all
yum upgrade -y zabbix-server-mysql zabbix-web-mysql 
yum -y install centos-release-scl
echo "ENABLE ZABBIX_WEB REPO"
read
yum remove zabbix-web-4.*
yum -y install zabbix-web-mysql-scl zabbix-apache-conf-scl
systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm
yum remove zabbix-web-4.*
yum -y install zabbix-web-mysql-scl zabbix-apache-conf-scl
systemctl restart zabbix-server zabbix-agent httpd rh-php72-php-fpm
systemctl enable zabbix-server zabbix-agent httpd rh-php72-php-fpm;;
 -ubuntu)
dpkg --purge zabbix-release
wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+$(lsb_release -sc)_all.deb &&
dpkg -i zabbix-release_5.0-1+$(lsb_release -sc)_all.deb &&
apt update &&
apt install -y --only-upgrade zabbix-server-mysql zabbix-frontend-php &&
apt-get install -y zabbix-apache-conf;;
  -sles)
echo "still waiting" ;;
 *)
echo "Use ./zabbix_upgrade.sh <distro>" ;;
esac

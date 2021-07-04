#!/bin/bash
#This script will create backup for all databases and rotate 7 days backups 
TIME=`date +%a_%b_%d_%y_`
FNAME=`date +%a_%b_%d_%y`
DELT=`date +%a`
mkdir -p /home/mysqlbackup/dbbackup/$FNAME

rm -vrf /home/mysqlbackup/dbbackup/$DELT*
mkdir -v /home/mysqlbackup/dbbackup/$FNAME
echo 'show databases;' | mysql -uadmin -p`cat /etc/psa/.psa.shadow` | grep -v ^Database | grep -v cphulk | grep -v eximstats | grep -v information_schema | grep -v performance_schema > /home/mysqlbackup/backuplist.txt
for i in `cat /home/mysqlbackup/backuplist.txt`; do mysqldump -uadmin -p`cat /etc/psa/.psa.shadow` $i > /home/mysqlbackup/dbbackup/$FNAME/$TIME$i.sql; echo "$i" >> /home/mysqlbackup/logs/`date +%Y-%m-%d`_completed_dump.txt; done

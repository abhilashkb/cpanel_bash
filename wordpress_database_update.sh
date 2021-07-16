#!/bin/bash

userp=""

tail /etc/userdomains | sort -k 2 > copy.txt

tail  /etc/trueuserdomains | sort -k 2 > copy1.txt

main='copy1.txt'
addon='copy.txt'


function dbmigration {


while read line
do
        user=$(echo $line | cut -d' ' -f2)
        domain=$(echo $line | cut -d' ' -f1 | sed 's/://g')

if [[ $userp != $user ]] ; then
m=1
else
m=$(($m+1))
fi

if [[ $2 -eq 2 ]]; then
domain=""
m=0
fi


if [ -e '/home/'$user'/public_html/'$domain'/'wp-config.php ]; then


cpapi2 --user=$user MysqlFE createdb db=$user"_wp"$m
uapi --user=$user Mysql create_user name=$user"_wpuser"$m password=$user"_sjwSsj5"
uapi --user=$user Mysql set_privileges_on_database user=$user"_wpuser"$m database=$user"_wp"$m privileges=DELETE,UPDATE,CREATE,ALTER

dbname=$( cat '/home/'$user'/public_html/'$domain'/'wp-config.php | grep DB_NAME | cut -d \' -f 4 )

#mysqldump -h 123.5.6.7 -u root -p'password' $dbname > "$dbname".sql
if [ $? -eq 0 ]; then

mysql -u $user"_user"$m -p '"$user"_wp"$m"' < "$dbname".sql

sed -i "/DB_NAME/s/'[^']*'/'$user"_wp"$m'/2" '/home/'$user'/public_html/'$domain'/'wp-config.php
sed -i "/DB_USER/s/'[^']*'/'$user"_wpuser"$m'/2" '/home/'$user'/public_html/'$domain'/'wp-config.php
sed -i "/DB_PASSWORD/s/'[^']*'/'$user"_sjwSsj5"'/2" '/home/'$user'/public_html/'$domain'/'wp-config.php

echo '/home/'$user'/'$domain'/'wp-config.php
#echo $user $domain

    echo OK
else
    echo FAILED  $user $domain >> bkupfailed.txt
fi

elif  [ -e '/home/'$user'/public_html/'$domain'/'configuration.php ]; then

cpapi2 --user=$user MysqlFE createdb db=$user"_jm"$m
uapi --user=$user Mysql create_user name=$user"_jmuser"$m password=$user"_sjwSsj5"
uapi --user=$user Mysql set_privileges_on_database user=$user"_jmuser"$m database=$user"_jm"$m privileges=DELETE,UPDATE,CREATE,ALTER


jdbname=$( grep -oP "\\\$db =.+?'\K[^']+" '/home/'$user'/public_html/'$domain'/'configuration.php )

#mysqldump -h 123.5.6.7 -u root -p'password' $jdbname > "$jdbname".sql
if [ $? -eq 0 ]; then

mysql -u $user"_user"$m -p '"$user"_jm"$m"' < "$jdbname".sql

sed -i "/db =/s/'[^']*'/'$user"_jm"$m'/1" '/home/'$user'/public_html/'$domain'/'configuration.php
sed -i "/user =/s/'[^']*'/'$user"_jmuser"$m'/1" '/home/'$user'/public_html/'$domain'/'configuration.php
sed -i "/password =/s/'[^']*'/'$user"_sjwSsj5"'/1" '/home/'$user'/public_html/'$domain'/'configuration.php
   echo OK
else
    echo FAILED  $user $domain >> bkupfailed.txt
fi

fi


userp=$user
echo $user $domain
done < $1

}


dbmigration $main 2
dbmigration $addon

#!/bin/bash

echo
echo "MAIL SPOOFING FROM EXIM LOG"
echo "+++++++++++++++++++++++"
echo
grep -A 10000000 "`date +%Y-%m-%d`" /var/log/exim_mainlog| grep -Eo '<=\ .*_login:[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' > authenticated.txt

while read line ;
do
sender=`echo $line | cut -d' ' -f2`

auth=`echo $line | awk -F '_login:' '{print $2}'`


if ! echo "$sender" |grep -wi "$auth" > /dev/null && echo "$sender" |grep -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' > /dev/null ; then


echo "$sender" authenticated by "$auth"

fi

done < authenticated.txt
echo

echo " SPOOFING IN CURRENT MAIL QUEUE"

echo "++++++++++++++++++++++++"

for i in `exim -bp | awk '{print $3}' | sed '/^$/d'` ;
do
authid=`exim -Mvh $i | grep 'auth_id' | cut -d' ' -f2`
fromadd=`exim -Mvh $i | grep '\ From:\ ' | grep -oE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}'`

if ! [ -z "$authid" ] && ! [ -z "$fromadd" ] && echo "$authid" | grep -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' > /dev/null ; then

if ! echo "$authid" | grep -iw "$fromadd" > /dev/null ; then

echo $fromadd authenticated by $authid

fi
fi
done


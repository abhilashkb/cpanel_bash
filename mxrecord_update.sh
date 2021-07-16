#!/bin/bash
ns1=ns1.skystradns.com
type=$1
domain=$2
username=`/scripts/whoowns $domain`

echo '1 aspmx.l.google.com
5 alt1.aspmx.l.google.com
5 alt2.aspmx.l.google.com
10 alt3.aspmx.l.google.com
10 alt4.aspmx.l.google.com' > /tmp/googlemx

omx=`echo $domain |sed 's/\./\-/g'`.mail.protection.outlook.com
echo 0 $omx > /tmp/outlookmx


> /tmp/mxrecords

if ! echo $domain | grep -Ew '[A-Za-z0-9.-]+\.[A-Za-z]{2,4}' > /dev/null ; then
echo Invalid domain name
exit 1
fi

if ! echo $type | grep -Ew 'office|google' > /dev/null ; then
echo Invalid mail provider
exit 1
fi

if ! dig ns $domain @$ns1 +short > /dev/null ; then
echo Domain not found
exit 1
fi


dig mx $domain @$ns1 +short |rev | cut -d'.' -f2- |rev > /tmp/mxrecords

if echo $type | grep -Ew 'google' > /dev/null ; then

for i in `cat /tmp/mxrecords |awk '{print $2}'`; do sed -i "/$i/d" /tmp/googlemx ; done

mxrecordfile=/tmp/googlemx
else

mxrecordfile=/tmp/outlookmx
for i in `cat /tmp/mxrecords |awk '{print $2}'`; do sed -i "/$i/d" /tmp/outlookmx ; done

fi



#DELETE MX record
while read line ;
do

pri=`echo $line | awk '{print $1}'`
mxr=`echo $line | awk '{print $2}'`

uapi --user=$username Email delete_mx domain=$domain exchanger=$mxr priority=$pri > /dev/null 2>&1

done < /tmp/mxrecords

whmapi1 disable_dkim domain=$domain > /dev/null 2>&1

#END Delete


#ADD SPF
if echo $type | grep -Ew 'google' > /dev/null ; then
mxrecordfile=/tmp/googlemx
uapi --user=$username EmailAuth install_spf_records domain=$domain record='v=spf1 %2Ba include:_spf.google.com include:relay.mailchannels.net -all' > /dev/null 2>&1

else

mxrecordfile=/tmp/outlookmx

# uapi --user=$username DNS mass_edit_zone zone=$domain serial='2021011601' add='{"dname":"'"$domain"'", "ttl":14400, "record_type":"SRV", "data":["100","1","443","sipdir.online.lync.com"]}'

whmapi1 addzonerecord domain=$domain name=_sip._tls class=IN ttl=86400 type=SRV priority="100" weight="1" port="443" target="sipdir.online.lync.com" > /dev/null 2>&1

whmapi1 addzonerecord domain=$domain name=_sipfederationtls._tc class=IN ttl=86400 type=SRV priority="100" weight="1" port="5061" target="sipfed.online.lync.com" > /dev/null 2>&1

uapi --user=$username EmailAuth install_spf_records domain=$domain record='v=spf1 %2Ba include:spf.protection.outlook.com include:relay.mailchannels.net -all' > /dev/null 2>&1
fi
#END SPF



#ADD MX RECORD

fail=0
while read line ;
do

pri=`echo $line | awk '{print $1}'`
mxr=`echo $line | awk '{print $2}'`

uapi --user=$username Email add_mx domain=$domain exchanger=$mxr priority=$pri > /dev/null 2>&1
[ $? -ne 0 ] && fail=1

done < $mxrecordfile
#END
/scripts/dnscluster synczone $domain


#Validation check

if [ $fail -eq 1 ] ; then

echo FAILED

else

echo SUCCESS

fi

#END


rm -f /tmp/outlookmx
rm -f /tmp/googlemx
rm -f /tmp/mxrecords

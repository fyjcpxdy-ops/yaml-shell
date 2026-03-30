#!/bin/bash

#!/bin/sh

bashpath=$(cd `dirname $0`; pwd)

now=`date +%Y%m%d_%H_%M_%S`

backpath=/etcd/etcdbackup/

respath=/etcd/
mkdir -p /etcd/etcdbackup/

etcdendpoints="http://localhost:2379"
etcdcmd="/usr/bin/etcdctl"
backupfile="$now.snapshot.db"

$etcdcmd --cacert /etc/kubernetes/pki/etcd/ca.pem --cert /etc/kubernetes/pki/etcd/etcd.pem --key /etc/kubernetes/pki/etcd/etcd-key.pem  --endpoints $etcdendpoints snapshot save $backpath/$backupfile


if [ `whoami` != 'root' ];then
        echo "Must be root run this scripts!!" >> /var/log/backup/messages
        exit
fi

ago=`date -d "-30 day" +%Y%m%d`
if [ ! -d $backpath ];then
        echo "This path [${$backpath}] not exist, please check." >> /var/log/backup/messages
        exit
fi
for i in `ls $backpath`
do
# Get datestamp and check it. For example: 20160526_11_00_00.bak.tar.gz
        datestamp=`echo $i | awk -F'_' '{print $1}'`
        check=`echo "$datestamp" | grep "^[0-9]\{8\}$"`
        if [ "$check" != '' ];then
                # Remove old files.
                if [ "$datestamp" -lt "$ago" ];then
                        /bin/rm -rf $backpath/$i
                fi
        fi
done

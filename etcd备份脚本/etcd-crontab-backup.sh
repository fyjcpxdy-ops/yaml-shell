#!/bin/bash
bashpath=$(
    cd $(dirname $0)
    pwd
)

#执行备份etcd脚本
sh ./etcd-v3.4.13-linux/backup-etcd.sh
#新增定时任务，每天凌晨三点执行一次备份etcd
crontab -l >conf
if ! grep -Fxq "0 3 * * * sh /root/deploy-external-etcd/etcd-v3.4.13-linux/backup-etcd.sh" conf; then
    echo "0 3 * * * sh /root/deploy-external-etcd/etcd-v3.4.13-linux/backup-etcd.sh" >>conf && crontab conf && rm -f conf
fi
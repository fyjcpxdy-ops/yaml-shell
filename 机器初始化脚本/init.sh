#/bin/bash
systemctl stop  firewalld
systemctl disable  firewalld
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
hostnamectl set-hostname heb25dx1k8s1mas2
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
yum install -y sshpass
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.15
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.120 
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.33
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.209
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.50  
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.42    
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.180  
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.232
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.242  
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.88 
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.211
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.147
sshpass -p "Istack@123" ssh-copy-id -o StrictHostKeyChecking=no -p 22 root@10.10.10.52
echo "10.10.10.23    heb25dx1k8s1mas3
10.10.10.15    heb25dx1k8s1mas2
10.10.10.120   heb25dx1k8s1mas1
10.10.10.33    heb25dx1k8s1share1
10.10.10.209   heb25dx1k8s1gfs3
10.10.10.50    heb25dx1k8s1gfs2
10.10.10.42    heb25dx1k8s1gfs1
10.10.10.180   heb25dx1k8s1har2
10.10.10.232   heb25dx1k8s1har1
10.10.10.242   heb25dx1k8s1build1
10.10.10.88    heb25dx1k8s1slave4
10.10.10.211   heb25dx1k8s1slave3
10.10.10.147   heb25dx1k8s1slave2
10.10.10.52    heb25dx1k8s1slave1" >> /etc/hosts


#/bin/bash
systemctl stop  firewalld
systemctl disable  firewalld
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce 0
hostnamectl set-hostname heb25dx1k8s1gfs2
echo "10.10.10.23    heb25dx1k8s1mas3
10.10.10.15    heb25dx1k8s1mas2
10.10.10.120   heb25dx1k8s1mas1
10.10.10.33    heb25dx1k8s1share1
10.10.10.209   heb25dx1k8s1gfs3
10.10.10.50    heb25dx1k8s1gfs2
10.10.10.42    heb25dx1k8s1gfs1
10.10.10.180   heb25dx1k8s1har2
10.10.10.232   heb25dx1k8s1har1
10.10.10.242   heb25dx1k8s1build1
10.10.10.88    heb25dx1k8s1slave4
10.10.10.211   heb25dx1k8s1slave3
10.10.10.147   heb25dx1k8s1slave2
10.10.10.52    heb25dx1k8s1slave1" >> /etc/hosts
#!/bin/bash

env=$1
if [ $# != 1 ]; then
    echo "Usage: $0 [top,top-ha,dev,qas,uat,prd]" >&2
    exit 1
fi
if [[ $env != "top" ]] && [[ $env != "top-ha" ]] && [[ $env != "dev" ]] && [[ $env != "qas" ]] && [[ $env != "uat" ]] && [[ $env != "prd" ]] && [[ $env != "pac" ]]; then
    echo "Usage: $0 [top,top-ha,dev,qas,uat,prd,pac]" >&2
    exit 1

fi
bashpath=$(
    cd $(dirname $0)
    pwd
)
k8s_master_ip=""
k8s_master_user=""
k8s_master_password=""
k8s_ips=""
k8s_node_ips=""
log_ip=""
k8s_domain_address=""
k8s_domain_address_enable=""
nfs_ip=""
nfs_path=""
glusterfs_clusterid=""
glusterfs_restfulurl=""

#主备
sync_master_cluster_ingress_address=""
sync_master_cluster_url=""
sync_master_cluster_name=""
sync_slave_cluster_ingress_address=""
sync_slave_cluster_name=""
sync_slave_cluster_url=""
sync_master_cluster_node_ip=""
sync_slave_cluster_node_ip=""
sync_enable=""

haproxy_ip=''
webapi_mysql_external=''
webapi_mysql_address=''
webapi_mysql_port=''
webapi_mysql_password=''

k8s_allipstr=""
k8s_masterstr=""
k8s_node_ipstr=""
k8s_node_userstr=""
k8s_node_passwordstr=""
k8s_node_systemstr=""
k8s_node_lbstr=""
k8s_node_velerostr=""
k8s_node_prometheusstr=""
k8s_node_miniostr=""
k8s_node_mysqlstr=""
k8s_node_taint_keystr=""
k8s_node_taint_effectstr=""
k8s_node_networkstr=""
k8s_node_machinestr=""
k8s_node_nvidia_device_enablestr=""
k8s_node_otterstr=""
k8s_node_harbornginxstr=""

k8s_master_ipstr=""
k8s_master_userstr=""
k8s_master_passwordstr=""
k8s_master_systemstr=""
k8s_master_taint_keystr=""
k8s_master_taint_effectstr=""
k8s_master_lbstr=""
k8s_master_velerostr=""
k8s_master_prometheusstr=""
k8s_master_miniostr=""
k8s_master_mysqlstr=""
k8s_master_networkstr=""
k8s_master_machinestr=""
k8s_master_nvidia_device_enablestr=""
k8s_master_otterstr=""
k8s_master_harbornginxstr=""

k8s_ipstr=""
k8s_vip=""
k8s_vip_port=""
ntp_server_ip=""
ntp_install=""

minio_size=""
minio_url=""

harbor_domain=""
harbor_url=""
harbor_address=""
harbor_vip=""
harbor_ip_list=""
harbor_password=""
harbor_storage_class=""
harbor_pgsql_storage_class=""
harbor_registry_size=""
harbor_chartmuseum_size=""
harbor_database_size=""
harbor_redis_size=""
harbor_jobservice_size=""
harbor_trivy_size=""
harbor_https_port=""
harbor_ha=""
harbor_pgsql_backup=""
harbor_pgsql_password=""
harbor_redis_password=""

macvlan_start=""
macvlan_end=""
macvlan_gateway=""
macvlan_vlanid=""
macvlan_netmask=""
macvlan_virtuleth=""
macvlan_physicaleth=""

f5_address=""
ingress_http_port=""
ingress_https_port=""
network_mode=""
calico_ipv4pool_cidr=""
calico_ipv4pool_ipip=""
docker_ip_cidr=""
service_cluster_ip_range=""
cluster_dns=""
top_master_ingress_address=""
top_slave_ingress_address=""
top_master_ingress_domain=""
master_scheduler=""
build_node_names=""
ctyun=""
etcd_external=""
kube_proxy_mode=""
mysql_password=""
redis_password=""

# logging
es_password=""

docker_install_path=""
kubelet_install_path=""
etcd_install_path=""

system_reserved_cpu=""
system_reserved_memory=""
system_reserved_ephemeral_storage=""
kube_reserved_cpu=""
kube_reserved_memory=""
kube_reserved_ephemeral_storage=""

# "ns1,ns2,ns3"
caas_namespaces=""
# 预置区的LB_VIP
pre_lb_vip=""
# 公共区：pub，预置区：pre，集群区：k8s
zone=""

# harbor节点IP
harbor_node_ip_arrary=""
# prometheus节点IP
prometheus_node_ip_arrary=""

echo -n "您确定要部署$env集群? [Y/n]:"
read iu

if [[ $iu != "Y" ]] && [[ $iu != "y" ]]; then
    exit 1
fi
find ../ -name "*.sh" -exec chmod +x {} \;

if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
    jsonStr=$(cat config-ha.json)
else
    jsonStr=$(cat config.json)
fi
echo $jsonStr | ./jq . &>/dev/null
if [ $? -ne 0 ]; then
    echo "Josn format error in the config json!"
    echo $jsonStr | ./jq .
    exit 1
fi

k8s_harbor_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .harbor'))
k8s_ips_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .ip'))
k8s_users_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .user'))
k8s_passwords_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .password'))
k8s_roles_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .role'))
k8s_system_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .system'))
k8s_taint_key_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .taint_key'))
k8s_taint_effect_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .taint_effect'))
k8s_lb_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .lb'))
k8s_velero_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .velero'))
k8s_prometheus_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .prometheus'))
k8s_minio_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .minio'))
k8s_mysql_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .mysql'))
k8s_network_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .network'))
k8s_machine_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .machine'))
k8s_nvidia_device_enable_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .nvidia_device_enable'))
k8s_harbornginx_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | ."harbor-nginx"'))
k8s_otter_array=($(echo $jsonStr | ./jq '.k8s_nodes[] | .otter'))

k8s_domain_address=$(echo $jsonStr | ./jq -r '.k8s_domain_address.address')
k8s_domain_address_enable=$(echo $jsonStr | ./jq -r '.k8s_domain_address.enable')
nfs_external=$(echo $jsonStr | ./jq -r '.nfs.external')
nfs_ip=$(echo $jsonStr | ./jq -r '.nfs.ip')
nfs_path=$(echo $jsonStr | ./jq -r '.nfs.path')
nfs_enable=$(echo $jsonStr | ./jq -r '.nfs.enable')
glusterfs_clusterid=$(echo $jsonStr | ./jq -r '.glusterfs.clusterid')
glusterfs_restfulurl=$(echo $jsonStr | ./jq -r '.glusterfs.restfulurl')
glusterfs_enable=$(echo $jsonStr | ./jq -r '.glusterfs.enable')

sync_master_cluster_ingress_address=$(echo $jsonStr | ./jq -r '.sync.master_cluster_ingress_address')
sync_master_cluster_url=$(echo $jsonStr | ./jq -r '.sync.master_cluster_url')
sync_master_cluster_name=$(echo $jsonStr | ./jq -r '.sync.master_cluster_name')
sync_slave_cluster_ingress_address=$(echo $jsonStr | ./jq -r '.sync.slave_cluster_ingress_address')
sync_slave_cluster_name=$(echo $jsonStr | ./jq -r '.sync.slave_cluster_name')
sync_slave_cluster_url=$(echo $jsonStr | ./jq -r '.sync.slave_cluster_url')
sync_master_cluster_node_ip=$(echo $jsonStr | ./jq -r '.sync.master_cluster_node_ip')
sync_slave_cluster_node_ip=$(echo $jsonStr | ./jq -r '.sync.slave_cluster_node_ip')
sync_enable=$(echo $jsonStr | ./jq -r '.sync.enable')

ceph_monitors=$(echo $jsonStr | ./jq -r '.ceph.monitors')
ceph_pool=$(echo $jsonStr | ./jq -r '.ceph.pool')
ceph_admin_id=$(echo $jsonStr | ./jq -r '.ceph.admin_id')
ceph_admin_secret=$(echo $jsonStr | ./jq -r '.ceph.admin_secret')
ceph_admin_secret_namespace=$(echo $jsonStr | ./jq -r '.ceph.admin_secret_namespace')
ceph_user_id=$(echo $jsonStr | ./jq -r '.ceph.user_id')
ceph_user_secret=$(echo $jsonStr | ./jq -r '.ceph.user_secret')
ceph_user_secret_namespace=$(echo $jsonStr | ./jq -r '.ceph.user_secret_namespace')
ceph_image_features=$(echo $jsonStr | ./jq -r '.ceph.image_features')
ceph_image_format=$(echo $jsonStr | ./jq -r '.ceph.image_format')
ceph_storage_limit=$(echo $jsonStr | ./jq -r '.ceph.storage_limit')
ceph_enable=$(echo $jsonStr | ./jq -r '.ceph.enable')
webapi_mysql_external=$(echo $jsonStr | ./jq -r '.webapi_mysql.external')
webapi_mysql_address=$(echo $jsonStr | ./jq -r '.webapi_mysql.address')
webapi_mysql_port=$(echo $jsonStr | ./jq -r '.webapi_mysql.port')
webapi_mysql_password=$(echo $jsonStr | ./jq -r '.webapi_mysql.password')
ntp_install=$(echo $jsonStr | ./jq -r '.ntp_install')

minio_size=$(echo $jsonStr | ./jq -r '.minio.size')
minio_url=$(echo $jsonStr | ./jq -r '.minio.url')

harbor_ip_list=$(echo $jsonStr | ./jq -r '.harbor.ip_list')
harbor_node_ip_arrary=$(echo $jsonStr | ./jq -r '.k8s_nodes[] | select(.harbor=="true") | .ip' | tr '\n' ',')
harbor_password=$(echo $jsonStr | ./jq -r '.harbor.password')
harbor_storage_class=$(echo $jsonStr | ./jq -r '.harbor.storage_class')
harbor_pgsql_storage_class=$(echo $jsonStr | ./jq -r '.harbor.pgsql_storage_class')
harbor_registry_size=$(echo $jsonStr | ./jq -r '.harbor.registry_size')
harbor_chartmuseum_size=$(echo $jsonStr | ./jq -r '.harbor.chartmuseum_size')
harbor_database_size=$(echo $jsonStr | ./jq -r '.harbor.database_size')
harbor_redis_size=$(echo $jsonStr | ./jq -r '.harbor.redis_size')
harbor_jobservice_size=$(echo $jsonStr | ./jq -r '.harbor.jobservice_size')
harbor_trivy_size=$(echo $jsonStr | ./jq -r '.harbor.trivy_size')
harbor_https_port=$(echo $jsonStr | ./jq -r '.harbor.https_port')
harbor_ha=$(echo $jsonStr | ./jq -r '.harbor.ha')
harbor_address=$(echo $jsonStr | ./jq -r '.harbor.address')
harbor_vip=$(echo $jsonStr | ./jq -r '.harbor.vip')
harbor_url=$(echo $jsonStr | ./jq -r '.harbor.url')
harbor_domain=$(echo $jsonStr | ./jq -r '.harbor.domain')
harbor_pgsql_backup=$(echo $jsonStr | ./jq -r '.harbor.pgsql_backup')
harbor_pgsql_password=$(echo $jsonStr | ./jq -r '.harbor.pgsql_password')
harbor_redis_password=$(echo $jsonStr | ./jq -r '.harbor.redis_password')

macvlan_start=$(echo $jsonStr | ./jq -r '.macvlan.start')
macvlan_end=$(echo $jsonStr | ./jq -r '.macvlan.end')
macvlan_gateway=$(echo $jsonStr | ./jq -r '.macvlan.gateway')
macvlan_vlanid=$(echo $jsonStr | ./jq -r '.macvlan.vlanid')
macvlan_netmask=$(echo $jsonStr | ./jq -r '.macvlan.netmask')
macvlan_virtuleth=$(echo $jsonStr | ./jq -r '.macvlan.virtuleth')
macvlan_physicaleth=$(echo $jsonStr | ./jq -r '.macvlan.physicaleth')

f5_address=$(echo $jsonStr | ./jq -r '.f5_address')
ingress_http_port=$(echo $jsonStr | ./jq -r '.ingress_http_port')
ingress_https_port=$(echo $jsonStr | ./jq -r '.ingress_https_port')
network_mode=$(echo $jsonStr | ./jq -r '.network_mode')
calico_ipv4pool_cidr=$(echo $jsonStr | ./jq -r '.calico_ipv4pool_cidr')
calico_ipv4pool_ipip=$(echo $jsonStr | ./jq -r '.calico_ipv4pool_ipip')
docker_ip_cidr=$(echo $jsonStr | ./jq -r '.docker_ip_cidr')
service_cluster_ip_range=$(echo $jsonStr | ./jq -r '.service_cluster_ip_range')
cluster_dns=$(echo $jsonStr | ./jq -r '.cluster_dns')
top_master_ingress_address=$(echo $jsonStr | ./jq -r '.top_master_ingress_address')
top_slave_ingress_address=$(echo $jsonStr | ./jq -r '.top_slave_ingress_address')
top_master_ingress_domain=$(echo $jsonStr | ./jq -r '.top_master_ingress_domain')
master_scheduler=$(echo $jsonStr | ./jq -r '.master_scheduler')
build_node_names=$(echo $jsonStr | ./jq -r '.build_node_names')
ctyun=$(echo $jsonStr | ./jq -r '.ctyun')
etcd_external=$(echo $jsonStr | ./jq -r '.etcd_external')
kube_proxy_mode=$(echo $jsonStr | ./jq -r '.kube_proxy_mode')
mysql_password=$(echo $jsonStr | ./jq -r '.mysql_password')
redis_password=$(echo $jsonStr | ./jq -r '.redis_password')

es_password=$(echo $jsonStr | ./jq -r '.logging.es_password')

docker_install_path=$(echo $jsonStr | ./jq -r '.docker_install_path')
kubelet_install_path=$(echo $jsonStr | ./jq -r '.kubelet_install_path')
etcd_install_path=$(echo $jsonStr | ./jq -r '.etcd_install_path')

system_reserved_cpu=$(echo $jsonStr | ./jq -r '.system_reserved.cpu')
system_reserved_memory=$(echo $jsonStr | ./jq -r '.system_reserved.memory')
system_reserved_ephemeral_storage=$(echo $jsonStr | ./jq -r '.system_reserved.ephemeral_storage')
kube_reserved_cpu=$(echo $jsonStr | ./jq -r '.kube_reserved.cpu')
kube_reserved_memory=$(echo $jsonStr | ./jq -r '.kube_reserved.memory')
kube_reserved_ephemeral_storage=$(echo $jsonStr | ./jq -r '.kube_reserved.ephemeral_storage')

caas_namespaces=$(echo $jsonStr | ./jq -r '.caas_namespaces')
pre_lb_vip=$(echo $jsonStr | ./jq -r '.pre_lb_vip')
zone=$(echo $jsonStr | ./jq -r '.zone')
prometheus_node_ip_arrary=$(echo $jsonStr | ./jq -r '.k8s_nodes[] | select(.prometheus=="true") | .ip' | tr '\n' ',')

if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
    etcd_ips_array=($(echo $jsonStr | ./jq '.etcd_nodes[] | .ip'))
    etcd_users_array=($(echo $jsonStr | ./jq '.etcd_nodes[] | .user'))
    etcd_passwords_array=($(echo $jsonStr | ./jq '.etcd_nodes[] | .password'))
    loadbalance_ips_array=($(echo $jsonStr | ./jq '.loadbalance_nodes[] | .ip'))
    loadbalance_users_array=($(echo $jsonStr | ./jq '.loadbalance_nodes[] | .user'))
    loadbalance_passwords_array=($(echo $jsonStr | ./jq '.loadbalance_nodes[] | .password'))
    loadbalance_interfaces_array=($(echo $jsonStr | ./jq '.loadbalance_nodes[] | .interface'))
    loadbalance_net_ids_array=($(echo $jsonStr | ./jq '.loadbalance_nodes[] | .net_id'))
    loadbalance_virtual_router_ids_array=($(echo $jsonStr | ./jq '.loadbalance_nodes[] | .virtual_router_id'))
    service_loadbalance_ips_array=($(echo $jsonStr | ./jq '.service_loadbalance_nodes[] | .ip'))
    service_loadbalance_users_array=($(echo $jsonStr | ./jq '.service_loadbalance_nodes[] | .user'))
    service_loadbalance_passwords_array=($(echo $jsonStr | ./jq '.service_loadbalance_nodes[] | .password'))
    service_loadbalance_interfaces_array=($(echo $jsonStr | ./jq '.service_loadbalance_nodes[] | .interface'))
    service_loadbalance_net_ids_array=($(echo $jsonStr | ./jq '.service_loadbalance_nodes[] | .net_id'))
    service_loadbalance_virtual_router_ids_array=($(echo $jsonStr | ./jq '.service_loadbalance_nodes[] | .virtual_router_id'))

    k8s_vip=$(echo $jsonStr | ./jq -r '.k8s_vip')
    k8s_vip_port=$(echo $jsonStr | ./jq -r '.k8s_vip_port')
else
    etcd_ips_array=""
    etcd_users_array=""
    etcd_passwords_array=""
    loadbalance_ips_array=""
    loadbalance_users_array=""
    loadbalance_passwords_array=""
    loadbalance_interfaces_array=""
    loadbalance_net_ids_array=""
    loadbalance_virtual_router_ids_array=""
    service_loadbalance_ips_array=""
    service_loadbalance_users_array=""
    service_loadbalance_passwords_array=""
    service_loadbalance_interfaces_array=""
    service_loadbalance_net_ids_array=""
    service_loadbalance_virtual_router_ids_array=""

    k8s_vip=""
    k8s_vip_port="6443"
fi

for ((c = 0; c < ${#k8s_ips_array[@]}; c++)); do
    ip=$(echo ${k8s_ips_array[c]%?} | sed 's/\"//g')
    user=$(echo ${k8s_users_array[c]%?} | sed 's/\"//g')
    password=$(echo ${k8s_passwords_array[c]%?} | sed 's/\"//g')

    if [ $? -ne 0 ]; then
        exit 1
    fi

    k8s_master_ip=${k8s_ips_array[0]}
    if [ ${k8s_roles_array[c]} == \""master"\" ]; then
        k8s_master_user=${k8s_users_array[c]}
        k8s_master_password=${k8s_passwords_array[c]}
        k8s_master_ipstr=$k8s_master_ipstr${k8s_ips_array[c]}","
        k8s_master_userstr=$k8s_master_userstr${k8s_users_array[c]}","
        k8s_master_passwordstr=$k8s_master_passwordstr${k8s_passwords_array[c]}","
        k8s_master_systemstr=$k8s_master_systemstr${k8s_system_array[c]}","
        k8s_master_taint_keystr=$k8s_master_taint_keystr${k8s_taint_key_array[c]}","
        k8s_master_taint_effectstr=$k8s_master_taint_effectstr${k8s_taint_effect_array[c]}","
        k8s_master_lbstr=$k8s_master_lbstr${k8s_lb_array[c]}","
        k8s_master_velerostr=$k8s_master_velerostr${k8s_velero_array[c]}","
        k8s_master_prometheusstr=$k8s_master_prometheusstr${k8s_prometheus_array[c]}","
        k8s_master_miniostr=$k8s_master_miniostr${k8s_minio_array[c]}","
        k8s_master_mysqlstr=$k8s_master_mysqlstr${k8s_mysql_array[c]}","
        k8s_master_otterstr=$k8s_master_otterstr${k8s_otter_array[c]}","
        k8s_master_harbornginxstr=$k8s_master_harbornginxstr${k8s_harbornginx_array[c]}","
        k8s_master_networkstr=$k8s_master_networkstr${k8s_network_array[c]}","
        k8s_master_machinestr=$k8s_master_machinestr${k8s_machine_array[c]}","
        k8s_master_nvidia_device_enablestr=$k8s_master_nvidia_device_enablestr${k8s_nvidia_device_enable_array[c]}","
    elif [ ${k8s_roles_array[c]} == \""slave"\" ]; then
        k8s_node_harborstr=$k8s_node_harborstr${k8s_harbor_array[c]}","
        k8s_node_ipstr=$k8s_node_ipstr${k8s_ips_array[c]}","
        k8s_node_userstr=$k8s_node_userstr${k8s_users_array[c]}","
        k8s_node_passwordstr=$k8s_node_passwordstr${k8s_passwords_array[c]}","
        k8s_node_taint_keystr=$k8s_node_taint_keystr${k8s_taint_key_array[c]}","
        k8s_node_taint_effectstr=$k8s_node_taint_effectstr${k8s_taint_effect_array[c]}","
        k8s_node_lbstr=$k8s_node_lbstr${k8s_lb_array[c]}","
        k8s_node_velerostr=$k8s_node_velerostr${k8s_velero_array[c]}","
        k8s_node_prometheusstr=$k8s_node_prometheusstr${k8s_prometheus_array[c]}","
        k8s_node_miniostr=$k8s_node_miniostr${k8s_minio_array[c]}","
        k8s_node_mysqlstr=$k8s_node_mysqlstr${k8s_mysql_array[c]}","
        k8s_node_otterstr=$k8s_node_otterstr${k8s_otter_array[c]}","
        k8s_node_harbornginxstr=$k8s_node_harbornginxstr${k8s_harbornginx_array[c]}","
        k8s_node_systemstr=$k8s_node_systemstr${k8s_system_array[c]}","
        k8s_node_networkstr=$k8s_node_networkstr${k8s_network_array[c]}","
        k8s_node_machinestr=$k8s_node_machinestr${k8s_machine_array[c]}","
        k8s_node_nvidia_device_enablestr=$k8s_node_nvidia_device_enablestr${k8s_nvidia_device_enable_array[c]}","
    fi
    k8s_ipstr=$k8s_ipstr${k8s_ips_array[c]}","
done

ntp_server_ip=$k8s_master_ip

if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
    k8s_master_ip=$k8s_vip
fi
k8s_ips=${k8s_ipstr%?}
k8s_node_ips=${k8s_node_ipstr%?}
k8s_node_users=${k8s_node_userstr%?}
k8s_node_passwords=${k8s_node_passwordstr%?}
k8s_node_harbors=${k8s_node_harborstr%?}
k8s_node_lbs=${k8s_node_lbstr%?}
k8s_node_systems=${k8s_node_systemstr%?}
k8s_node_veleros=${k8s_node_velerostr%?}
k8s_node_prometheuss=${k8s_node_prometheusstr%?}
k8s_node_minios=${k8s_node_miniostr%?}
k8s_node_mysqls=${k8s_node_mysqlstr%?}
k8s_node_otters=${k8s_node_otterstr%?}
k8s_node_taint_keys=${k8s_node_taint_keystr%?}
k8s_node_taint_effects=${k8s_node_taint_effectstr%?}
k8s_node_harbors=${k8s_node_harborstr%?}
k8s_node_harbornginxs=${k8s_node_harbornginxstr%?}
k8s_node_networks=${k8s_node_networkstr%?}
k8s_node_machines=${k8s_node_machinestr%?}
k8s_node_nvidia_device_enables=${k8s_node_nvidia_device_enablestr%?}
k8s_master_ips=${k8s_master_ipstr%?}
k8s_master_users=${k8s_master_userstr%?}
k8s_master_passwords=${k8s_master_passwordstr%?}
k8s_master_systems=${k8s_master_systemstr%?}
k8s_master_lbs=${k8s_master_lbstr%?}
k8s_master_veleros=${k8s_master_velerostr%?}
k8s_master_prometheuss=${k8s_master_prometheusstr%?}
k8s_master_minios=${k8s_master_miniostr%?}
k8s_master_mysqls=${k8s_master_mysqlstr%?}
k8s_master_otters=${k8s_master_otterstr%?}
k8s_master_harbornginxs=${k8s_master_harbornginxstr%?}
k8s_master_taint_keys=${k8s_master_taint_keystr%?}
k8s_master_taint_effects=${k8s_master_taint_effectstr%?}
k8s_master_networks=${k8s_master_networkstr%?}
k8s_master_machines=${k8s_master_machinestr%?}
k8s_master_nvidia_device_enables=${k8s_master_nvidia_device_enablestr%?}
k8s_ips=$(echo $k8s_ips | sed 's/\"//g')
k8s_node_ips=$(echo $k8s_node_ips | sed 's/\"//g')
k8s_node_users=$(echo $k8s_node_users | sed 's/\"//g')
k8s_node_passwords=$(echo $k8s_node_passwords | sed 's/\"//g')
k8s_node_harbors=$(echo $k8s_node_harbors | sed 's/\"//g')
k8s_node_lbs=$(echo $k8s_node_lbs | sed 's/\"//g')
k8s_node_veleros=$(echo $k8s_node_veleros | sed 's/\"//g')
k8s_node_prometheuss=$(echo $k8s_node_prometheuss | sed 's/\"//g')
k8s_node_minios=$(echo $k8s_node_minios | sed 's/\"//g')
k8s_node_systems=$(echo $k8s_node_systems | sed 's/\"//g')
k8s_node_mysqls=$(echo $k8s_node_mysqls | sed 's/\"//g')
k8s_node_taint_keys=$(echo $k8s_node_taint_keys | sed 's/\"//g')
k8s_node_taint_effects=$(echo $k8s_node_taint_effects | sed 's/\"//g')
k8s_node_networks=$(echo $k8s_node_networks | sed 's/\"//g')
k8s_node_machines=$(echo $k8s_node_machines | sed 's/\"//g')
k8s_node_nvidia_device_enables=$(echo $k8s_node_nvidia_device_enables | sed 's/\"//g')
k8s_node_harbornginxs=$(echo $k8s_node_harbornginxs | sed 's/\"//g')
k8s_node_otters=$(echo $k8s_node_otters | sed 's/\"//g')

k8s_master_ips=$(echo $k8s_master_ips | sed 's/\"//g')
k8s_master_users=$(echo $k8s_master_users | sed 's/\"//g')
k8s_master_passwords=$(echo $k8s_master_passwords | sed 's/\"//g')
k8s_master_ip=$(echo $k8s_master_ip | sed 's/\"//g')
k8s_master_user=$(echo $k8s_master_user | sed 's/\"//g')
k8s_master_password=$(echo $k8s_master_password | sed 's/\"//g')
k8s_master_systems=$(echo $k8s_master_systems | sed 's/\"//g')
k8s_master_lbs=$(echo $k8s_master_lbs | sed 's/\"//g')
k8s_master_veleros=$(echo $k8s_master_veleros | sed 's/\"//g')
k8s_master_prometheuss=$(echo $k8s_master_prometheuss | sed 's/\"//g')
k8s_master_minios=$(echo $k8s_master_minios | sed 's/\"//g')
k8s_master_mysqls=$(echo $k8s_master_mysqls | sed 's/\"//g')
k8s_master_taint_keys=$(echo $k8s_master_taint_keys | sed 's/\"//g')
k8s_master_taint_effects=$(echo $k8s_master_taint_effects | sed 's/\"//g')
k8s_master_networks=$(echo $k8s_master_networks | sed 's/\"//g')
k8s_master_machines=$(echo $k8s_master_machines | sed 's/\"//g')
k8s_master_nvidia_device_enables=$(echo $k8s_master_nvidia_device_enables | sed 's/\"//g')
k8s_master_harbornginxs=$(echo $k8s_master_harbornginxs | sed 's/\"//g')
k8s_master_otters=$(echo $k8s_master_otters | sed 's/\"//g')
ntp_server_ip=$(echo $ntp_server_ip | sed 's/\"//g')

#ETCD
etcd_ipstr=""
etcd_userstr=""
etcd_passwordstr=""
etcd_ips=""
etcd_users=""
etcd_passwords=""
for ((c = 0; c < ${#etcd_ips_array[@]}; c++)); do
    ip=$(echo ${etcd_ips_array[c]%?} | sed 's/\"//g')
    user=$(echo ${etcd_users_array[c]%?} | sed 's/\"//g')
    password=$(echo ${etcd_passwords_array[c]%?} | sed 's/\"//g')

    if [ $? -ne 0 ]; then
        exit 1
    fi
    etcd_ipstr=$etcd_ipstr${etcd_ips_array[c]}","
    etcd_userstr=$etcd_userstr${etcd_users_array[c]}","
    etcd_passwordstr=$etcd_passwordstr${etcd_passwords_array[c]}","
done

etcd_ips=${etcd_ipstr%?}
etcd_users=${etcd_userstr%?}
etcd_passwords=${etcd_passwordstr%?}

etcd_ips=$(echo $etcd_ips | sed 's/\"//g')
etcd_users=$(echo $etcd_users | sed 's/\"//g')
etcd_passwords=$(echo $etcd_passwords | sed 's/\"//g')

etcd_arr=$(echo $etcd_ips | tr "," "\n")

#loadbalance keepalived
loadbalance_ipstr=""
loadbalance_userstr=""
loadbalance_passwordstr=""
loadbalance_ips=""
loadbalance_users=""
loadbalance_passwords=""
loadbalance_interfaces=""
loadbalance_net_ids=""
loadbalance_virtual_router_ids=""

for ((c = 0; c < ${#loadbalance_ips_array[@]}; c++)); do
    ip=$(echo ${loadbalance_ips_array[c]%?} | sed 's/\"//g')
    user=$(echo ${loadbalance_users_array[c]%?} | sed 's/\"//g')
    password=$(echo ${loadbalance_passwords_array[c]%?} | sed 's/\"//g')

    if [ $? -ne 0 ]; then
        exit 1
    fi
    loadbalance_ipstr=$loadbalance_ipstr${loadbalance_ips_array[c]}","
    loadbalance_userstr=$loadbalance_userstr${loadbalance_users_array[c]}","
    loadbalance_passwordstr=$loadbalance_passwordstr${loadbalance_passwords_array[c]}","

    loadbalance_interfacestr=$loadbalance_interfacestr${loadbalance_interfaces_array[c]}","
    loadbalance_net_idstr=$loadbalance_net_idstr${loadbalance_net_ids_array[c]}","
    loadbalance_virtual_router_idstr=$loadbalance_virtual_router_idstr${loadbalance_virtual_router_ids_array[c]}","
done

loadbalance_ips=${loadbalance_ipstr%?}
loadbalance_users=${loadbalance_userstr%?}
loadbalance_passwords=${loadbalance_passwordstr%?}

loadbalance_interfaces=${loadbalance_interfacestr%?}
loadbalance_net_ids=${loadbalance_net_idstr%?}
loadbalance_virtual_router_ids=${loadbalance_virtual_router_idstr%?}

loadbalance_ips=$(echo $loadbalance_ips | sed 's/\"//g')
loadbalance_users=$(echo $loadbalance_users | sed 's/\"//g')
loadbalance_passwords=$(echo $loadbalance_passwords | sed 's/\"//g')

loadbalance_interfaces=$(echo $loadbalance_interfaces | sed 's/\"//g')
loadbalance_net_ids=$(echo $loadbalance_net_ids | sed 's/\"//g')
loadbalance_virtual_router_ids=$(echo $loadbalance_virtual_router_ids | sed 's/\"//g')

#service loadbalance keepalived
service_loadbalance_ipstr=""
service_loadbalance_userstr=""
service_loadbalance_passwordstr=""
service_loadbalance_ips=""
service_loadbalance_users=""
service_loadbalance_passwords=""
service_loadbalance_interfaces=""
service_loadbalance_net_ids=""
service_loadbalance_virtual_router_ids=""

for ((c = 0; c < ${#service_loadbalance_ips_array[@]}; c++)); do
    ip=$(echo ${service_loadbalance_ips_array[c]%?} | sed 's/\"//g')
    user=$(echo ${service_loadbalance_users_array[c]%?} | sed 's/\"//g')
    password=$(echo ${service_loadbalance_passwords_array[c]%?} | sed 's/\"//g')

    if [ $? -ne 0 ]; then
        exit 1
    fi
    service_loadbalance_ipstr=$service_loadbalance_ipstr${service_loadbalance_ips_array[c]}","
    service_loadbalance_userstr=$service_loadbalance_userstr${service_loadbalance_users_array[c]}","
    service_loadbalance_passwordstr=$service_loadbalance_passwordstr${service_loadbalance_passwords_array[c]}","

    service_loadbalance_interfacestr=$service_loadbalance_interfacestr${service_loadbalance_interfaces_array[c]}","
    service_loadbalance_net_idstr=$service_loadbalance_net_idstr${service_loadbalance_net_ids_array[c]}","
    service_loadbalance_virtual_router_idstr=$service_loadbalance_virtual_router_idstr${service_loadbalance_virtual_router_ids_array[c]}","
done

service_loadbalance_ips=${service_loadbalance_ipstr%?}
service_loadbalance_users=${service_loadbalance_userstr%?}
service_loadbalance_passwords=${service_loadbalance_passwordstr%?}

service_loadbalance_interfaces=${service_loadbalance_interfacestr%?}
service_loadbalance_net_ids=${service_loadbalance_net_idstr%?}
service_loadbalance_virtual_router_ids=${service_loadbalance_virtual_router_idstr%?}

service_loadbalance_ips=$(echo $service_loadbalance_ips | sed 's/\"//g')
service_loadbalance_users=$(echo $service_loadbalance_users | sed 's/\"//g')
service_loadbalance_passwords=$(echo $service_loadbalance_passwords | sed 's/\"//g')

service_loadbalance_interfaces=$(echo $service_loadbalance_interfaces | sed 's/\"//g')
service_loadbalance_net_ids=$(echo $service_loadbalance_net_ids | sed 's/\"//g')
service_loadbalance_virtual_router_ids=$(echo $service_loadbalance_virtual_router_ids | sed 's/\"//g')

#harbor_address_all=$harbor_address
#if [[ $harbor_https_port != "443" ]]; then
#    harbor_address_all=$harbor_address:$harbor_https_port
#fi

#harbor_address_all=$(echo $harbor_address_all | sed -E "s/^([0-9a-zA-Z.-]+:[0-9]+)\/\1/\1/")

# 仅当harbor_address不含端口、且端口不是443时，才加端口
#if [[ $harbor_https_port != "443" ]] && [[ $harbor_address != *":"* ]]; then
#    harbor_address_all=$harbor_address:$harbor_https_port
#fi

# 正确的Harbor地址拼接逻辑
# 初始化基础地址
# 仅当端口不是443、且基础地址未包含端口时，添加端口

# 最终校验：移除地址中重复的域名+端口（兜底处理）
# 正确的Harbor地址拼接逻辑（彻底去重+防特殊字符）
# 1. 先清理原始harbor_address的多余字符（引号、空格、换行）
harbor_address_clean=$(echo $harbor_address | sed -e 's/^["'\'']//' -e 's/["'\'']$//' -e 's/[[:space:]]//g' -e '/^$/d')

# 2. 初始化基础地址（仅保留域名，移除端口）
# 提取域名部分（去掉:端口）
harbor_domain_only=$(echo $harbor_address_clean | sed -E 's/(:[0-9]+)$//')
harbor_address_all=$harbor_domain_only

# 3. 仅当端口不是443时，添加端口（无论原始地址是否带端口）
if [[ $harbor_https_port != "443" ]]; then
    harbor_address_all="${harbor_domain_only}:${harbor_https_port}"
fi

# 4. 终极去重：移除所有路径中重复的域名+端口（覆盖所有场景）
# 比如把 "harbor.xxx.cn:9443/harbor.xxx.cn:9443/xxx" 改成 "harbor.xxx.cn:9443/xxx"
harbor_address_all=$(echo $harbor_address_all | sed -E "s/^($harbor_address_all)\/$harbor_address_all/$harbor_address_all/" | sed -E "s/($harbor_address_all)\/$harbor_address_all/$harbor_address_all/g")

# 5. 调试：打印最终结果（确认无误后可删除）
echo "最终修复后的harbor_address_all: [$harbor_address_all]"


function execShell() {
    echo ""
    echo $echoStr
    echo "Running ..."
    echo "" >>/var/log/deploy.log
    echo $echoStr >>/var/log/deploy.log
    echo $shellStr >>/var/log/deploy.log
    eval $shellStr
    if [ $? -ne 0 ]; then
        echo "Shell 命令执行失败."
    fi

    echo "End"

}

#选择菜单

echo "0 终止部署"
#echo "99 一键部署"
echo "1 安装前环境检查以及免密码登录配置"
if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]]; then
    if [[ $ctyun == "true" ]]; then
        echo "  部署k8s master节点:  2.2 部署master 节点"
        echo "3 部署calico"
        echo "4 部署k8s node节点"
        echo "5.1 部署minIO"
        echo "5.2 部署harbor vip (harbor高可用需要部署，需要客户提供vip)"
        echo "6.1 部署lvm csi plugin"
        echo "6.2 部署中间件operator"
        echo "6.3 部署harbor"
        echo "6.4 导入harbor数据"
        echo "7 部署多网卡"
    else
        echo "  部署k8s master节点:  2.1 部署master的负载均衡节点 2.2 部署master 节点"
        echo "3 部署calico"
        echo "4 部署k8s node节点"
        echo "5.1 部署minIO"
        echo "5.2 部署harbor vip (harbor高可用需要部署，需要客户提供vip)"
        echo "6.1 部署lvm csi plugin"
        echo "6.2 部署中间件operator"
        echo "6.3 部署harbor"
        echo "6.4 导入harbor数据"
        echo "7 部署多网卡"
    fi

elif [[ $env != "pac" ]]; then
    echo "2 部署k8s master节点"
fi

# add by gaoshaopu
if [[ $env == "pac" ]]; then
    cat <<EOF
部署k8s master节点:  2.1 部署master的负载均衡节点 2.2 部署master 节点
3 部署calico
4 部署k8s node节点
8.0 部署admission-webhook
8.1 部署glusterfs
6.1 部署lvm csi plugin
5.1 部署minIO
8.4 部署ingress-controller
部署 harbor: 6.2 部署中间件operator 5.2 部署harbor vip 6.3 部署harbor 6.4 导入harbor数据
8.6 部署监控
8.10 部署crd-controller
8.12 部署velero
8.13 部署分区爆发
8.19 部署内存证书
8.20 部署维多利亚
EOF
fi

storage="部署glusterfs"
if [[ $glusterfs_enable == "true" ]]; then
    storage="部署glusterfs"
fi
if [[ $ceph_enable == "true" ]]; then
    storage="部署ceph"
fi
if [[ $nfs_enable == "true" ]]; then
    storage="部署nfs"
fi

if [[ $env == "top-ha" ]] || [[ $env == "top" ]]; then
    cat <<EOF
8.0 部署admission
8.1 $storage
8.3 部署Jenkins
8.4 部署ingress-controller
8.5 部署日志
8.6 部署监控
8.8 部署观云台管理平台
8.9 部署istio
8.10 部署crd-controller
8.11 部署Sonar
8.12 部署velero
8.13 部署分区爆发
8.15 部署双中心同步（主集群）8.16 部署双中心同步（备集群）
8.17 初始化数据
8.18 备份etcd(集群全部正常后执行)
8.19 部署内存证书监控
8.20 部署维多利亚
EOF
elif [[ $env != "pac" ]]; then
    cat <<EOF
8.0 部署admission
8.1 $storage
8.3 部署ingress-controller
8.4 部署日志
8.5 部署监控
8.7 部署crd-controller
8.8 部署velero
8.9 部署分区爆发
8.10 部署gpu组件
8.11 安装维多利亚
EOF
fi

# 添加脚本执行选型
cat <<EOF
10.1 输出用户权限配置说明
10.2 配置基线用户sudo权限配置(glusterfs需手动执行)
10.3 部署合规的Kubeconfig(仅配置caas与master节点的sysview) 10.4 删除kubeconfig(caas与master节点的sysview)
11.1 测试部署完成的容器集群 11.2 基线检查
11.3 配置永久token
11.4 添加ETCD备份监控
EOF

# if [[ $zone == "pub" ]] || [[ $zone == "pre" ]]
# then
#     echo "10.3 部署合规的Secret配置（zone: pub/pre）"
# fi

while [[ 1 == 1 ]]; do
    echo -n "输入您要部署的模块编号:"
    read num

    #清空日志
    if [ $num != "0" ]; then
        echo "" >/var/log/deploy.log
    fi

    if [ $num == "0" ]; then
        exit 0
    fi

    #echo -n "请确认是安装or卸载？ [I/U]:"
    echo -n "请确认安装？ [Y/n]:"
    read iu

    if [[ $iu == "Y" ]] || [[ $iu == "y" ]]; then
        if [[ $num == "99" ]]; then
            echoStr="99 一键部署"
            echo $echoStr >>/var/log/deploy.log
        fi

        if [[ $num == "99" ]] || [[ $num == "1" ]]; then
            if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                arr_user=(${etcd_users//,/ })
                arr_password=(${etcd_passwords//,/ })
                arr=(${etcd_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    echoStr="$num 安装前环境检查以及免密码登录配置---"${arr[$i]}
                    shellStr="/bin/bash $bashpath/precheck.sh '${arr_user[$i]}' '${arr[$i]}' '${arr_password[$i]}'  "
                    execShell $echoStr $shellStr $num
                done

                arr_user=(${loadbalance_users//,/ })
                arr_password=(${loadbalance_passwords//,/ })
                arr=(${loadbalance_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    echoStr="$num 安装前环境检查以及免密码登录配置---"${arr[$i]}
                    shellStr="/bin/bash $bashpath/precheck.sh '${arr_user[$i]}' '${arr[$i]}' '${arr_password[$i]}' "
                    execShell $echoStr $shellStr $num
                done

                arr_user=(${k8s_master_users//,/ })
                arr_password=(${k8s_master_passwords//,/ })
                arr=(${k8s_master_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    echoStr="$num 安装前环境检查以及免密码登录配置---"${arr[$i]}
                    shellStr="/bin/bash $bashpath/precheck.sh '${arr_user[$i]}' '${arr[$i]}' '${arr_password[$i]}' "
                    execShell $echoStr $shellStr $num
                done

            else
                echoStr="$num 安装前环境检查以及免密码登录配置---"${arr[$i]}
                shellStr="/bin/bash $bashpath/precheck.sh '$k8s_master_user' '$k8s_master_ip' '$k8s_master_password'  "
                execShell $echoStr $shellStr $num
            fi

            arr_user=(${k8s_node_users//,/ })
            arr_password=(${k8s_node_passwords//,/ })
            arr=(${k8s_node_ips//,/ })
            for ((i = 0; i < ${#arr[@]}; i++)); do
                echoStr="$num 安装前环境检查以及免密码登录配置---"${arr[$i]}
                shellStr="/bin/bash $bashpath/precheck.sh '${arr_user[$i]}' '${arr[$i]}' '${arr_password[$i]}'  "
                execShell $echoStr $shellStr $num
            done

        fi

        if [[ $num == "99" ]] || [[ $num =~ ^2 ]]; then
            if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                if [[ $num == "99" ]] || [[ $num == "2" ]] || [[ $num == "2.1" ]]; then
                    arr_user=(${loadbalance_users//,/ })
                    arr_password=(${loadbalance_passwordstr//,/ })
                    arr=(${loadbalance_ips//,/ })
                    arr_interfaces=(${loadbalance_interfaces//,/ })
                    arr_net_ids=(${loadbalance_net_ids//,/ })
                    arr_virtual_router_ids=(${loadbalance_virtual_router_ids//,/ })
                    for ((i = 0; i < ${#arr[@]}; i++)); do
                        role="slave"
                        if [ $i -eq 0 ]; then
                            role="master"
                        fi
                        echoStr="$num 部署master的负载均衡节点 haproxy ---"${arr[$i]}
                        shellStr="$bashpath/../deploy-loadbalance-apiserver/install.sh ${arr[$i]} ${arr_user[$i]} ${arr_password[$i]} $k8s_master_ips $k8s_vip_port >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                        echoStr="$num 部署master的负载均衡节点 keepalived---"${arr[$i]}
                        shellStr="$bashpath/../deploy-keepalived/install.sh ${arr[$i]} ${arr_user[$i]} ${arr_password[$i]} $role $k8s_master_ip ${arr_interfaces[$i]} ${arr_net_ids[$i]} ${arr_virtual_router_ids[$i]} "k8s" $k8s_vip_port >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                fi

                if [[ $num == "99" ]] || [[ $num == "2" ]] || [[ $num == "2.2" ]]; then
                    arr_user=(${k8s_master_users//,/ })
                    arr_password=(${k8s_master_passwords//,/ })
                    arr_system=(${k8s_master_systems//,/ })
                    arr_taint_key=(${k8s_master_taint_keys//,/ })
                    arr_taint_effect=(${k8s_master_taint_effects//,/ })
                    arr_lb=(${k8s_master_lbs//,/ })
                    arr_velero=(${k8s_master_veleros//,/ })
                    arr_prometheus=(${k8s_master_prometheuss//,/ })
                    arr_minio=(${k8s_master_minios//,/ })
                    arr_mysql=(${k8s_master_mysqls//,/ })
                    arr_network=(${k8s_master_networks//,/ })
                    arr_machine=(${k8s_master_machines//,/ })
                    arr_nvidia_device_enable=(${k8s_master_nvidia_device_enables//,/ })
                    arr=(${k8s_master_ips//,/ })
                    for ((i = 0; i < ${#arr[@]}; i++)); do
                        if [[ $i == 0 ]]; then
                            if [[ $ntp_install == "true" ]]; then
                                echoStr="$num ntp server---"$ntp_server_ip
                                shellStr="$bashpath/../deploy-ntp/install-server.sh >> /var/log/deploy.log"
                                execShell $echoStr $shellStr $num
                            fi
                            echoStr="$num 部署master 节点---"${arr[$i]}
                            shellStr="$bashpath/../deploy-k8s/install-master-sub.sh  $harbor_address_all $k8s_master_ip  $etcd_ips "ha" $k8s_domain_address $k8s_domain_address_enable ${arr[$i]} $top_master_ingress_address false ${arr_system[$i]} ${arr_lb[$i]} ${arr_mysql[$i]} $master_scheduler $f5_address $ntp_server_ip $ctyun $k8s_vip_port ${arr_taint_key[$i]}  ${arr_taint_effect[$i]} ${arr_network[$i]} $docker_ip_cidr $service_cluster_ip_range $cluster_dns $top_master_ingress_domain ${arr_machine[$i]} $etcd_external $kube_proxy_mode $harbor_domain $etcd_install_path $docker_install_path $kubelet_install_path $system_reserved_cpu $system_reserved_memory $kube_reserved_cpu $kube_reserved_memory $system_reserved_ephemeral_storage $kube_reserved_ephemeral_storage ${arr_nvidia_device_enable[$i]} $ntp_install >> /var/log/deploy.log"
                            execShell $echoStr $shellStr $num
                        else
                            echoStr="$num 获取master 节点join token---"${arr[$i]}
                            shellStr="${bashpath}/../deploy-k8s/gen-master-join-token.sh ${k8s_vip} ${k8s_vip_port} ${kubelet_install_path}"
                            execShell $echoStr $shellStr $num
                            shellStr="$bashpath/../deploy-k8s/scp-kubernetes.sh ${arr[$i]} ${arr_user[$i]} ${arr_password[$i]} $harbor_address_all $k8s_master_ip $ntp_server_ip $etcd_ips "ha" $k8s_domain_address $k8s_domain_address_enable $top_master_ingress_address true ${arr_system[$i]}   ${arr_lb[$i]}  ${arr_mysql[$i]} $master_scheduler $f5_address $ctyun $k8s_vip_port ${arr_taint_key[$i]} ${arr_taint_effect[$i]} ${arr_network[$i]} $docker_ip_cidr  $service_cluster_ip_range $cluster_dns $top_master_ingress_domain ${arr_machine[$i]} $etcd_external $kube_proxy_mode $harbor_domain $etcd_install_path $docker_install_path $kubelet_install_path $system_reserved_cpu $system_reserved_memory $kube_reserved_cpu $kube_reserved_memory $system_reserved_ephemeral_storage $kube_reserved_ephemeral_storage ${arr_nvidia_device_enable[$i]} $ntp_install >> /var/log/deploy.log"
                            execShell $echoStr $shellStr $num
                        fi
                        for user in caas sysview appview; do
                            echoStr="$num 配置Master节点${user}用户sudo权限配置---"${arr[$i]}
                            shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh ${arr_user[$i]} ${arr[$i]} ${user} docker ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                            execShell $echoStr $shellStr $num
                        done
                    done
                    sleep 10s
                    arr_user=(${loadbalance_users//,/ })
                    arr_password=(${loadbalance_passwordstr//,/ })
                    arr=(${loadbalance_ips//,/ })
                    arr_interfaces=(${loadbalance_interfaces//,/ })
                    arr_net_ids=(${loadbalance_net_ids//,/ })
                    arr_virtual_router_ids=(${loadbalance_virtual_router_ids//,/ })
                    for ((i = 0; i < ${#arr[@]}; i++)); do
                        echoStr="$num 修改keepalived配置文件---"${arr[$i]}
                        shellStr="$bashpath/../deploy-keepalived/install-change-kp-conf.sh ${arr[$i]} ${arr_user[$i]}  >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                fi

            else
                arr_es=(${k8s_master_ess//,/ })
                arr_mysql=(${k8s_master_mysqls//,/ })
                arr_system=(${k8s_master_systems//,/ })
                arr_taint_key=(${k8s_master_taint_keys//,/ })
                arr_taint_effect=(${k8s_master_taint_effects//,/ })
                arr_lb=(${k8s_master_lbs//,/ })
                arr_network=(${k8s_master_networks//,/ })
                arr_machine=(${k8s_master_machines//,/ })
                arr_nvidia_device_enable=(${k8s_master_nvidia_device_enables//,/ })
                if [[ $ntp_install == "true" ]]; then
                    echoStr="$num ntp server---"$ntp_server_ip
                    shellStr="$bashpath/../deploy-ntp/install-server.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi
                status=$(kubectl get nodes | grep $k8s_master_ip | awk '{print $2}')
                echoStr="2 部署k8s master节点"
                if [ "$status"status != "Ready"status ]; then
                    echo "$harbor_address"
                    echo "$harbor_https_port"
                    echo "$harbor_address_all"
                    shellStr="$bashpath/../deploy-k8s/install-master-sub.sh  $harbor_address_all $k8s_master_ip "null" "null" $k8s_domain_address $k8s_domain_address_enable $k8s_master_ip $top_master_ingress_address false ${arr_system[0]} ${arr_lb[0]} ${arr_mysql[0]} $master_scheduler $f5_address $ntp_server_ip $ctyun $k8s_vip_port   ${arr_taint_key[0]}  ${arr_taint_effect[0]} ${arr_network[0]}  $docker_ip_cidr $service_cluster_ip_range  $cluster_dns $top_master_ingress_domain ${arr_machine[0]} false $kube_proxy_mode $harbor_domain $etcd_install_path $docker_install_path $kubelet_install_path $system_reserved_cpu $system_reserved_memory $kube_reserved_cpu $kube_reserved_memory $system_reserved_ephemeral_storage $kube_reserved_ephemeral_storage ${arr_nvidia_device_enable[0]} $ntp_install >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                    for user in caas sysview appview; do
                        echoStr="$num 配置Master节点${user}用户sudo权限配置---"${arr[$i]}
                        shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh ${arr_user[$i]} ${arr[$i]} ${user} docker ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                    shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh $k8s_master_user $k8s_master_ip ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                else
                    echo "master already install"
                fi
            fi
        fi

        if [[ $num == "99" ]] || [[ $num =~ ^3 ]]; then
            if [[ $num == "99" ]] || [[ $num == "3" ]] || [[ $num == "3.1" ]]; then
                echoStr="$num 部署calico"
                etcd_url="https://"$k8s_master_ip":2379"
                if [[ $network_mode == "calico" ]]; then
                    echoStr="部署$network_mode网络"
                    shellStr="$bashpath/../deploy-calico/install.sh $ntp_server_ip $etcd_url $calico_ipv4pool_cidr $calico_ipv4pool_ipip $etcd_external $etcd_ips  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi
                if [[ $network_mode == "macvlan" ]]; then
                    echoStr="部署$network_mode网络"
                    shellStr="$bashpath/../deploy-macvlan/install.sh $macvlan_start $macvlan_end $macvlan_gateway $macvlan_vlanid $macvlan_netmask $macvlan_virtuleth $macvlan_physicaleth  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi
                if [[ $network_mode == "flannel" ]]; then
                    echoStr="部署$network_mode网络"
                    shellStr="$bashpath/../deploy-flannel/install.sh $etcd_url >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi
            fi

            if [[ $num == "99" ]] || [[ $num == "3" ]] || [[ $num == "3.2" ]]; then
                echoStr="$num 部署混合网络(calico+macvlan)"
                etcd_url="https://"$k8s_master_ip":2379"
                if [[ $network_mode == "calico+macvlan" ]]; then
                    echoStr="部署calico网络"
                    shellStr="$bashpath/../deploy-calico/install.sh $ntp_server_ip $etcd_url $calico_ipv4pool_cidr $calico_ipv4pool_ipip $etcd_external $etcd_ips >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                    echoStr="部署macvlan网络"
                    shellStr="$bashpath/../deploy-macvlan/install.sh $macvlan_start $macvlan_end $macvlan_gateway $macvlan_vlanid $macvlan_netmask $macvlan_virtuleth $macvlan_physicaleth  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi
            fi

        fi

        if [[ $num == "99" ]] || [[ $num == "4" ]]; then
            arr_user=(${k8s_node_users//,/ })
            arr_password=(${k8s_node_passwords//,/ })
            arr_harbor=(${k8s_node_harbors//,/ })
            arr_harbornginx=(${k8s_node_harbornginxs//,/ })
            arr_lb=(${k8s_node_lbs//,/ })
            arr_system=(${k8s_node_systems//,/ })
            arr_taint_key=(${k8s_node_taint_keys//,/ })
            arr_taint_effect=(${k8s_node_taint_effects//,/ })
            arr_velero=(${k8s_node_veleros//,/ })
            arr_prometheus=(${k8s_node_prometheuss//,/ })
            arr_minio=(${k8s_node_minios//,/ })
            arr_mysql=(${k8s_node_mysqls//,/ })
            arr_network=(${k8s_node_networks//,/ })
            arr_machine=(${k8s_node_machines//,/ })
            arr_nvidia_device_enable=(${k8s_node_nvidia_device_enables//,/ })
            arr=(${k8s_node_ips//,/ })
            arr_otter=(${k8s_node_otters//,/ })
            for ((i = 0; i < ${#arr[@]}; i++)); do
                status=$(kubectl get nodes | grep ${arr[$i]} | awk '{print $2}')
                echoStr="$num 部署k8s node节点---"${arr[$i]}
                if [ "$status"status != "Ready"status ]; then
                    {
                        echoStr="$num 获取master 节点join token---"${arr[$i]}
                        shellStr="${bashpath}/../deploy-k8s/gen-master-join-token.sh ${k8s_vip} ${k8s_vip_port} ${kubelet_install_path}"
                        execShell $echoStr $shellStr $num
                        shellStr="$bashpath/../deploy-k8s/install-node.sh ${arr[$i]} ${arr_user[$i]} ${arr_password[$i]}  $harbor_address_all $k8s_master_ip $ntp_server_ip  ${arr_lb[$i]} $ntp_install ${arr_mysql[$i]} ${arr_system[$i]} ${arr_taint_key[$i]}  ${arr_taint_effect[$i]} ${arr_harbor[$i]} ${arr_velero[$i]} ${arr_prometheus[$i]} ${arr_minio[$i]} ${arr_network[$i]} $docker_ip_cidr ${arr_harbornginx[$i]} ${arr_otter[$i]} ${arr_machine[$i]} $f5_address $harbor_domain $k8s_domain_address_enable $k8s_domain_address $docker_install_path $kubelet_install_path ${arr_nvidia_device_enable[$i]} ${cluster_dns} $ntp_install >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num

                        for user in caas sysview appview; do
                            echoStr="$num 配置Master节点${user}用户sudo权限配置---"${arr[$i]}
                            shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh ${arr_user[$i]} ${arr[$i]} ${user} docker ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                            execShell $echoStr $shellStr $num
                        done
                    }
                else
                    echo "node: ${arr[$i]} already install"
                fi
            done

        fi

        if [[ $num == "99" ]] || [[ $num =~ ^5 ]]; then

            if [[ $num == "99" ]] || [[ $num == "5" ]] || [[ $num == "5.1" ]]; then
                echoStr="$num 部署minIO"
                shellStr="$bashpath/../deploy-minio/install.sh $minio_size >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

            if [[ $num == "99" ]] || [[ $num == "5" ]] || [[ $num == "5.2" ]]; then
                echoStr="$num 部署harbor vip (harbor高可用需要部署，需要客户提供vip)"
                shellStr="$bashpath/../deploy-vip/install.sh $harbor_vip >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

        fi

        if [[ $num == "99" ]] || [[ $num =~ ^6 ]]; then
            if [[ $num == "99" ]] || [[ $num == "6" ]] || [[ $num == "6.1" ]]; then
                echoStr="$num 部署lvm csi plugin"
                shellStr="$bashpath/../deploy-lvm-csi-plugin/install.sh $kubelet_install_path >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

            if [[ $num == "99" ]] || [[ $num == "6" ]] || [[ $num == "6.2" ]]; then
                echoStr="$num 部署中间件operator"
                shellStr="$bashpath/../deploy-middleware-operator/install.sh $harbor_address $harbor_https_port >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

            if [[ $num == "99" ]] || [[ $num == "6" ]] || [[ $num == "6.3" ]]; then
                echoStr="$num 部署harbor"
                shellStr="$bashpath/../deploy-harbor/install.sh $harbor_url $harbor_domain $harbor_ip_list $harbor_storage_class $harbor_pgsql_storage_class $harbor_redis_size $harbor_registry_size $harbor_chartmuseum_size $harbor_jobservice_size $harbor_trivy_size $harbor_database_size $harbor_ha $harbor_password $harbor_pgsql_backup $minio_url $harbor_pgsql_password $harbor_redis_password $harbor_node_ip_arrary >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

            if [[ $num == "99" ]] || [[ $num == "6" ]] || [[ $num == "6.4" ]]; then
                echoStr="$num 导入harbor数据"
                shellStr="$bashpath/../deploy-harbor/import.sh  >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

        fi

        if [[ $num == "99" ]] || [[ $num == "7" ]]; then
            echoStr="$num 部署多网卡"
            shellStr="$bashpath/../deploy-multus/install.sh $harbor_address $harbor_https_port  >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num
        fi

        if [[ $num == "99" ]] || [[ $num =~ ^8 ]]; then
            if [[ $env == "top-ha" ]] || [[ $env == "top" ]] || [[ $env == "pac" ]]; then
                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.0" ]]; then
                    echoStr="$num 部署admission, 请确保caas-admission-webhook.caas-system起来之后再执行后续步骤"
                    shellStr="$bashpath/../deploy-admission-webhook/install.sh $top_master_ingress_address $top_slave_ingress_address $top_master_ingress_domain >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $glusterfs_enable == "true" ]]; then
                    if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.1" ]]; then
                        echoStr="$num 部署glusterfs"
                        shellStr="$bashpath/../deploy-glusterfs/install.sh $glusterfs_clusterid $glusterfs_restfulurl >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num

                        arr_nodes=(${k8s_master_ips//,/ })
                        ssh_ip=$(echo ${glusterfs_restfulurl} | sed -n 's/.*\/\/\([0-9.]*\):.*/\1/p')
                        echoStr="$num 开始创建iptables规则"
                        shellStr="$bashpath/../deploy-glusterfs/iptables.sh root ${ssh_ip} ${arr_nodes[0]} >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    fi
                fi

                if [[ $ceph_enable == "true" ]]; then
                    if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.1" ]]; then
                        echoStr="$num 部署ceph"
                        shellStr="$bashpath/../deploy-ceph/install.sh $ceph_monitors $ceph_pool $ceph_admin_id $ceph_admin_secret $ceph_admin_secret_namespace $ceph_user_id $ceph_user_secret $ceph_user_secret_namespace $ceph_image_features $ceph_image_format $ceph_storage_limit  >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    fi
                fi

                # if [[ $nfs_enable == "true" ]]; then
                #     if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.1" ]]; then
                #         echoStr="$num 部署nfs"
                #         shellStr="$bashpath/../deploy-nfs/install.sh $nfs_ip $nfs_external $nfs_path >> /var/log/deploy.log"
                #         execShell $echoStr $shellStr $num
                #     fi
                # fi

                # if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.2" ]]; then
                #     echoStr="$num 部署节点上下线服务"
                #     shellStr="$bashpath/../deploy-k8s/node-up-down/install-node-up-down.sh $ntp_server_ip $f5_address $docker_ip_cidr $mysql_password $docker_install_path >> /var/log/deploy.log"
                #     execShell $echoStr $shellStr $num
                # fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.3" ]]; then
                    echoStr="$num 部署Jenkins"
                    shellStr="$bashpath/../deploy-jenkins/install.sh $k8s_master_ip $f5_address  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.4" ]]; then
                    echoStr="$num 部署ingress-controller"
                    shellStr="$bashpath/../deploy-ingress-controller/install.sh $ingress_http_port $ingress_https_port $zone >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num

                    if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                        arr_user=(${service_loadbalance_users//,/ })
                        arr_password=(${service_loadbalance_passwordstr//,/ })
                        arr=(${service_loadbalance_ips//,/ })
                        arr_interfaces=(${service_loadbalance_interfaces//,/ })
                        arr_net_ids=(${service_loadbalance_net_ids//,/ })
                        arr_virtual_router_ids=(${service_loadbalance_virtual_router_ids//,/ })
                        type="ingress"
                        for ((i = 0; i < ${#arr[@]}; i++)); do
                            role="slave"
                            if [ $i -eq 0 ]; then
                                role="master"
                            fi
                            echoStr="$num 部署应用的负载均衡节点 keepalived---"${arr[$i]}
                            shellStr="$bashpath/../deploy-keepalived/install.sh ${arr[$i]} ${arr_user[$i]} ${arr_password[$i]} $role $f5_address ${arr_interfaces[$i]} ${arr_net_ids[$i]} ${arr_virtual_router_ids[$i]} ${type} $k8s_vip_port>> /var/log/deploy.log"
                            execShell $echoStr $shellStr $num
                        done
                    fi
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.5" ]]; then
                    echoStr="$num 部署日志"
                    shellStr="$bashpath/../deploy-log/install.sh $es_password  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.6" ]]; then
                    echoStr="$num 部署监控"
                    shellStr="$bashpath/../deploy-monitor/install.sh $top_master_ingress_address $etcd_external $etcd_ips $zone $pre_lb_vip >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.7" ]]; then
                    echoStr="$num 部署故障隔离"
                    shellStr="$bashpath/../deploy-problem-isolation/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.8" ]]; then
                    echoStr="$num 部署观云台管理平台"
                    shellStr="$bashpath/../deploy-web-api/install.sh $harbor_address $k8s_master_ip $webapi_mysql_external $webapi_mysql_address $webapi_mysql_port $harbor_password $f5_address $k8s_domain_address $k8s_domain_address_enable $network_mode $harbor_https_port $build_node_names $sync_enable $es_password $mysql_password $redis_password >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.9" ]]; then
                    echoStr="$num 部署istio"
                    shellStr="$bashpath/../deploy-istio/install.sh $harbor_address $harbor_https_port >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.10" ]]; then
                    echoStr="$num 部署crd-controller"
                    shellStr="$bashpath/../deploy-crd-controller/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.11" ]]; then
                    echoStr="$num 部署Sonar代码扫描"
                    shellStr="$bashpath/../deploy-sonar/install.sh  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.12" ]]; then
                    echoStr="$num 部署velero"
                    shellStr="$bashpath/../deploy-velero/install.sh $minio_url >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.13" ]]; then
                    echoStr="$num 部署分区爆发"
                    shellStr="$bashpath/../deploy-autoscaler/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.14" ]]; then
                    echoStr="$num 部署kubefed"
                    shellStr="$bashpath/../deploy-kubefed/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.15" ]]; then
                    echoStr="$num 部署双中心同步（主集群）"
                    shellStr="$bashpath/../deploy-hc-sync/install-master-cluster.sh $sync_master_cluster_ingress_address $sync_master_cluster_url $sync_master_cluster_name $sync_slave_cluster_ingress_address $sync_slave_cluster_name $sync_slave_cluster_url $sync_master_cluster_node_ip $sync_slave_cluster_node_ip  >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.16" ]]; then
                    echoStr="$num 部署双中心同步（备集群）"
                    shellStr="$bashpath/../deploy-hc-sync/install-slave-cluster.sh $sync_master_cluster_ingress_address $sync_master_cluster_url $sync_master_cluster_name $sync_slave_cluster_ingress_address $sync_slave_cluster_name $sync_slave_cluster_url $sync_master_cluster_node_ip $sync_slave_cluster_node_ip >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.17" ]]; then
                    echoStr="$num 初始化数据"
                    shellStr="$bashpath/../deploy-init-data/install.sh $f5_address $es_password >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.18" ]]; then
                    echoStr="$num 备份etcd"
                    shellStr="$bashpath/../backup-etcd/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.19" ]]; then
                    arr_user=(${k8s_master_users//,/ })
                    arr=(${k8s_master_ips//,/ })
                    set -e
                    for ((i = 0; i < ${#arr[@]}; i++)); do
                        echoStr="$num 部署内存证书监控---"${arr[$i]}
                        shellStr="$bashpath/../deploy-monitor/memory-cert-exporter/install-memory-cert-exporter.sh ${arr_user[$i]} ${arr[$i]} appview >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                    set +e
                    echoStr="$num 重启node-exporter生效内存证书监控"
                    shellStr="$bashpath/../deploy-monitor/memory-cert-exporter/poststart.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.20" ]]; then
                    echoStr="$num 安装维多利亚"
                    shellStr="$bashpath/../deploy-monitor/install-vm.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

            else
                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.0" ]]; then
                    echoStr="$num 部署admission, 请确保caas-admission-webhook.caas-system起来之后再执行后续步骤"
                    shellStr="$bashpath/../deploy-admission-webhook/install.sh $top_master_ingress_address $top_slave_ingress_address $top_master_ingress_domain >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $glusterfs_enable == "true" ]]; then
                    if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.1" ]]; then
                        echoStr="$num 部署glusterfs"
                        shellStr="$bashpath/../deploy-glusterfs/install.sh $glusterfs_clusterid $glusterfs_restfulurl >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    fi
                    arr_prometheus_node=(${prometheus_node_ip_arrary//,/ })
                    ssh_ip=$(echo ${glusterfs_restfulurl} | sed -n 's/.*\/\/\([0-9.]*\):.*/\1/p')
                    echoStr="$num 开始创建iptables规则"
                    shellStr="$bashpath/../deploy-glusterfs/iptables.sh root ${ssh_ip} ${arr_prometheus_node[0]} >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $ceph_enable == "true" ]]; then
                    if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.1" ]]; then
                        echoStr="$num 部署ceph"
                        shellStr="$bashpath/../deploy-ceph/install.sh $ceph_monitors $ceph_pool $ceph_admin_id $ceph_admin_secret $ceph_admin_secret_namespace $ceph_user_id $ceph_user_secret $ceph_user_secret_namespace $ceph_image_features $ceph_image_format $ceph_storage_limit  >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    fi
                fi

                # if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.2" ]]; then
                #     echoStr="$num 部署节点上下线服务"
                #     shellStr="$bashpath/../deploy-k8s/node-up-down/install-node-up-down.sh $ntp_server_ip $top_master_ingress_address $docker_ip_cidr $mysql_password >> /var/log/deploy.log"
                #     execShell $echoStr $shellStr $num
                # fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.3" ]]; then
                    echoStr="$num 部署ingress-controller"
                    shellStr="$bashpath/../deploy-ingress-controller/install.sh  $ingress_http_port $ingress_https_port $zone >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num

                    if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                        arr_user=(${service_loadbalance_users//,/ })
                        arr_password=(${service_loadbalance_passwordstr//,/ })
                        arr=(${service_loadbalance_ips//,/ })
                        arr_interfaces=(${service_loadbalance_interfaces//,/ })
                        arr_net_ids=(${service_loadbalance_net_ids//,/ })
                        arr_virtual_router_ids=(${service_loadbalance_virtual_router_ids//,/ })
                        type="ingress"
                        for ((i = 0; i < ${#arr[@]}; i++)); do
                            role="slave"
                            if [ $i -eq 0 ]; then
                                role="master"
                            fi
                            echoStr="$num 部署应用的负载均衡节点 keepalived---"${arr[$i]}
                            shellStr="$bashpath/../deploy-keepalived/install.sh ${arr[$i]} ${arr_user[$i]} ${arr_password[$i]} $role $f5_address ${arr_interfaces[$i]} ${arr_net_ids[$i]} ${arr_virtual_router_ids[$i]} ${type} $k8s_vip_port>> /var/log/deploy.log"
                            execShell $echoStr $shellStr $num
                        done
                    fi
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.4" ]]; then
                    echoStr="$num 部署日志"
                    shellStr="$bashpath/../deploy-log/install.sh $es_password >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.5" ]]; then
                    echoStr="$num 部署监控"
                    shellStr="$bashpath/../deploy-monitor/install.sh $top_master_ingress_address $etcd_external $etcd_ips $zone $pre_lb_vip >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.6" ]]; then
                    echoStr="$num 部署故障隔离"
                    shellStr="$bashpath/../deploy-problem-isolation/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.7" ]]; then
                    echoStr="$num 部署crd-controller"
                    shellStr="$bashpath/../deploy-crd-controller/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.8" ]]; then
                    echoStr="$num 部署velero"
                    shellStr="$bashpath/../deploy-velero/install.sh $minio_url >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.9" ]]; then
                    echoStr="$num 部署分区爆发"
                    shellStr="$bashpath/../deploy-autoscaler/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.10" ]]; then
                    echoStr="$num 部署gpu组件"
                    shellStr="$bashpath/../deploy-gpu/install.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi

                if [[ $num == "99" ]] || [[ $num == "8" ]] || [[ $num == "8.11" ]]; then
                    echoStr="$num 安装维多利亚"
                    shellStr="$bashpath/../deploy-monitor/install-vm.sh >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                fi
            fi
        fi

        if [[ $num == "99" ]] || [[ $num == "9" ]]; then
            if [[ $num == "99" ]] || [[ $num == "9" ]]; then
                str="$k8s_domain_address"
                suffix=${str#*.}
                suffix2=$(echo $str | cut -d '.' -f 2-3)
                echoStr="$num 部署wrapper"
                shellStr="$bashpath/../deploy-wrapper/install.sh $harbor_password $f5_address $harbor_domain helm-wrapper.${suffix} helm-wrapper-${suffix2//./-} >> /var/log/deploy.log"
                execShell $echoStr $shellStr $num
            fi

        fi

        # ==============================================================================
        # ============================= | Update by xuchao | ===========================
        # ============================= | Data：202309 ^_^ | ===========================
        # ==============================================================================
        if [[ $num == "99" ]] || [[ $num == "10.1" ]]; then
            sh ${bashpath}/../deploy-non-root/README.sh
        elif [[ $num == "10.2" ]]; then
            # 高可用部署
            if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                # Master节点
                arr_user=(${k8s_master_users//,/ })
                arr=(${k8s_master_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    for user in caas sysview appview; do
                        echoStr="$num 配置Master节点${user}用户sudo权限配置---"${arr[$i]}
                        shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh ${arr_user[$i]} ${arr[$i]} ${user} docker ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                done

                # Etcd节点
                arr_user=(${etcd_users//,/ })
                arr=(${etcd_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    echoStr="$num Etcd节点创建合规的用户&sudo权限配置---"${arr[$i]}
                    for user in caas sysview appview; do
                        echoStr="$num 配置Master节点${user}用户sudo权限配置---"${arr[$i]}
                        shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh ${arr_user[$i]} ${arr[$i]} ${user} docker ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                done

                # node节点
                arr_user=(${k8s_node_users//,/ })
                arr=(${k8s_node_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    for user in caas sysview appview; do
                        echoStr="$num 配置Master节点${user}用户sudo权限配置---"${arr[$i]}
                        shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh ${arr_user[$i]} ${arr[$i]} ${user} docker ${docker_install_path} ${kubelet_install_path} ${etcd_install_path} >> /var/log/deploy.log"
                        execShell $echoStr $shellStr $num
                    done
                done

                # #   非高可用部署
                #   else
                #       # Master节点
                #       echoStr="$num Master节点创建合规的用户&sudo权限配置"${k8s_master_ip}
                #       shellStr="$bashpath/../deploy-non-root/remote-setting-user.sh $k8s_master_user $k8s_master_ip >> /var/log/deploy.log"
                #       execShell $echoStr $shellStr $num
            fi
        fi

        if [[ $num == "99" ]] || [[ $num == "10.3" ]]; then
            # 高可用部署
            if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                arr_user=(${k8s_master_users//,/ })
                arr=(${k8s_master_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    echoStr="$num Master节点配置合规caas用户Kubeconfig---"${arr[$i]}
                    shellStr="$bashpath/../deploy-non-root/install-kubeconfig.sh apply ${arr[$i]} ${arr_user[$i]} $k8s_vip $k8s_vip_port caas $caas_namespaces >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num

                    echoStr="$num Master节点配置合规sysview用户Kubeconfig---"${arr[$i]}
                    shellStr="$bashpath/../deploy-non-root/install-kubeconfig.sh apply ${arr[$i]} ${arr_user[$i]} $k8s_vip $k8s_vip_port sysview all >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                done
            # # 非高可用部署
            # else
            #     echoStr="$num 部署合规的Kubeconfig"
            #     shellStr="$bashpath/../deploy-non-root/install-kubeconfig.sh $k8s_domain_address 6443 $caas_namespaces $k8s_master_user $k8s_master_ip >> /var/log/deploy.log"
            #     execShell $echoStr $shellStr $num
            fi
        fi

        if [[ $num == "99" ]] || [[ $num == "10.4" ]]; then
            # 高可用部署
            if [[ $env == "top-ha" ]] || [[ $env == "uat" ]] || [[ $env == "prd" ]] || [[ $env == "pac" ]]; then
                arr_user=(${k8s_master_users//,/ })
                arr=(${k8s_master_ips//,/ })
                for ((i = 0; i < ${#arr[@]}; i++)); do
                    echoStr="$num Master节点删除caas用户Kubeconfig---"${arr[$i]}
                    shellStr="$bashpath/../deploy-non-root/install-kubeconfig.sh delete ${arr[$i]} ${arr_user[$i]} $k8s_vip $k8s_vip_port caas $caas_namespaces >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num

                    echoStr="$num Master节点删除sysview用户Kubeconfig---"${arr[$i]}
                    shellStr="$bashpath/../deploy-non-root/install-kubeconfig.sh delete ${arr[$i]} ${arr_user[$i]} $k8s_vip $k8s_vip_port sysview all >> /var/log/deploy.log"
                    execShell $echoStr $shellStr $num
                done
            # # 非高可用部署
            # else
            #     echoStr="$num 部署合规的Kubeconfig"
            #     shellStr="$bashpath/../deploy-non-root/install-kubeconfig.sh $k8s_domain_address 6443 $caas_namespaces $k8s_master_user $k8s_master_ip >> /var/log/deploy.log"
            #     execShell $echoStr $shellStr $num
            fi
        fi

        if [[ $num == "99" ]] || [[ $num == "11.1" ]]; then
            # arr=(${loadbalance_ips//,/ })
            echoStr="$num 测试部署完成的容器集群"
            shellStr="$bashpath/../deploy-test/functional-tests/test.sh ${harbor_url} ${harbor_password} ${loadbalance_ips} https://${k8s_vip}:${k8s_vip_port} ${service_loadbalance_ips} ${f5_address} >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num
        fi

        if [[ $num == "99" ]] || [[ $num == "11.2" ]]; then
            echoStr="$num 基线检查"
            shellStr="$bashpath/../deploy-test/base-line-tests/tool.sh check all ${k8s_master_ips} ${etcd_ips} ${k8s_node_ips} >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num
        fi

        if [[ $num == "99" ]] || [[ $num == "11.3" ]]; then
            echoStr="$num 配置永久token"
            shellStr="$bashpath/../deploy-k8s/patch_permanent_token.sh --upgrade >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num

            echoStr="$num 检查配置"
            shellStr="$bashpath/../deploy-k8s/patch_permanent_token.sh --check >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num
        fi

        if [[ $num == "99" ]] || [[ $num == "11.4" ]]; then
            echoStr="$num 添加ETCD备份监控--拷贝etcd脚本到目标节点"
            shellStr="$bashpath/../deploy-monitor/backup-etcd-monitor/call.sh --scp-etcd-script ${etcd_ips} ${etcd_install_path} /usr/bin/etcdctl >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num

            echoStr="$num 添加ETCD备份监控--在etcd节点安装node-exporter"
            shellStr="$bashpath/../deploy-monitor/backup-etcd-monitor/call.sh --install-node-exporter ${etcd_ips} >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num
            sleep 5s
            
            echoStr="$num 添加ETCD备份监控--检查node-exporter是否正常"
            shellStr="$bashpath/../deploy-monitor/backup-etcd-monitor/call.sh --test-node-exporter ${etcd_ips} >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num

            echoStr="$num 添加ETCD备份监控--创建servicemonitor"
            shellStr="$bashpath/../deploy-monitor/backup-etcd-monitor/call.sh --create-etcd-servicemonitor ${etcd_ips} >> /var/log/deploy.log"
            execShell $echoStr $shellStr $num
        fi
    fi
done

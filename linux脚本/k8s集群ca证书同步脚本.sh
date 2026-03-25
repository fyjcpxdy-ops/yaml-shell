#/bin/bash
# 定义其他Master节点列表（替换为你的实际节点IP/主机名）
OTHER_MASTERS=("10.20.81.31" "10.20.81.32" "10.20.81.68")  # 假设另外两个Master的IP

# 循环同步新证书到每个Master节点
for MASTER in "${OTHER_MASTERS[@]}"; do
  echo "同步证书到 ${MASTER}..."
  # 复制新证书到目标Master（需确保SSH免密登录）
  scp /etc/kubernetes/pki/apiserver.{crt,key} root@${MASTER}:/etc/kubernetes/pki/
  # 在目标Master上重启apiserver
  ssh root@${MASTER} "kubectl delete pod -n kube-system -l component=kube-apiserver"
  echo "${MASTER} 证书同步完成！"
done
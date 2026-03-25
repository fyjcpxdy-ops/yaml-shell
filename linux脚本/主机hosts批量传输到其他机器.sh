#!/bin/bash
# 步骤1：解析/etc/hosts，提取有效主机IP（排除回环、注释、空行，去重）
export TARGET_HOSTS=$(grep -v '^#' /etc/hosts | grep -v '^$' | grep -v -E '127.0.0.1|::1' | awk '{print $1}' | sort -u)

# 步骤2：查看提取到的主机数量和列表
echo "===== 解析/etc/hosts结果 ====="
echo "总共有 $(echo ${TARGET_HOSTS} | wc -w) 台目标主机"
echo "目标主机IP列表：${TARGET_HOSTS}"
echo "=============================="

# 步骤3：遍历所有主机，传输/etc/hosts文件（需root权限，默认用SSH密钥认证）
for host in ${TARGET_HOSTS}; do
  echo -e "\n正在传输/etc/hosts到主机 ${host}..."
  # scp传输（覆盖目标主机的/etc/hosts，-q静默模式，-o处理SSH连接超时）
  scp -q -o ConnectTimeout=5 /etc/hosts root@${host}:/etc/hosts
  if [ $? -eq 0 ]; then
    echo "✅ 主机 ${host} 传输成功"
  else
    echo "❌ 主机 ${host} 传输失败（可能网络不通/SSH认证失败）"
  fi
done
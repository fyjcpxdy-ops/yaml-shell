#!/bin/bash
# 脚本功能：批量配置多主机禁用IPv6（避免重复写入+修正scp路径+增加容错）
# 作者：xxx
# 日期：2025-12-30

# ===================== 第一步：定义全局变量 =====================
CONF_FILE="/etc/sysctl.d/70-disable-ipv6.conf"
HOSTS_FILE="./hosts.txt"  # 主机列表文件（每行第二列为主机名/IP）
BACKUP_SUFFIX=".bak-$(date +%Y%m%d%H%M%S)"  # 备份后缀（带时间戳）

# ===================== 第二步：容错检查 =====================
# 1. 检查hosts.txt是否存在
if [ ! -f "$HOSTS_FILE" ]; then
    echo -e "\033[31m错误：主机列表文件 $HOSTS_FILE 不存在！\033[0m"
    exit 1
fi

# 2. 检查hosts.txt是否为空
HOST_LIST=$(awk '{print $2}' "$HOSTS_FILE" | grep -v "^$")
if [ -z "$HOST_LIST" ]; then
    echo -e "\033[31m错误：主机列表文件 $HOSTS_FILE 中无有效主机！\033[0m"
    exit 1
fi

# ===================== 第三步：本地配置（覆盖写入，避免重复） =====================
echo -e "\033[32m[1/3] 生成本地IPv6禁用配置文件（覆盖模式）...\033[0m"
# 先备份原有配置（避免覆盖丢失）
if [ -f "$CONF_FILE" ]; then
    cp "$CONF_FILE" "${CONF_FILE}${BACKUP_SUFFIX}"
    echo -e "已备份原有配置到：${CONF_FILE}${BACKUP_SUFFIX}"
fi

# 覆盖写入配置（> 代替 >>，避免重复追加）
cat > "$CONF_FILE" <<EOF
# 禁用所有接口IPv6（全局）
net.ipv6.conf.all.disable_ipv6 = 1
# 禁用新接口默认IPv6
net.ipv6.conf.default.disable_ipv6 = 1
# 禁用回环接口IPv6
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

# 立即生效本地配置（无需重启）
sysctl -p "$CONF_FILE" >/dev/null 2>&1
echo -e "本地IPv6禁用配置已生成并生效：$CONF_FILE"

# ===================== 第四步：批量推送配置到远程主机 =====================
echo -e "\033[32m[2/3] 批量推送配置文件到远程主机...\033[0m"
for h in $HOST_LIST; do
    # 跳过空行/无效主机
    if [ -z "$h" ]; then
        continue
    fi

    # 检查SSH连通性（免密）
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$h" "echo >/dev/null 2>&1"; then
        echo -e "\033[33m警告：主机 $h SSH免密登录失败，跳过该主机！\033[0m"
        continue
    fi

    # 推送配置文件（修正scp路径：去掉$h:后空格）
    if scp -q "$CONF_FILE" "$h:$CONF_FILE"; then
        # 远程生效配置（无需重启）
        ssh "$h" "sysctl -p $CONF_FILE >/dev/null 2>&1"
        echo -e "✅ 主机 $h：配置推送成功并生效"
    else
        echo -e "\033[31m❌ 主机 $h：配置推送失败！\033[0m"
    fi
done

# ===================== 第五步：可选：批量重启主机（如需永久生效，取消注释） =====================
# echo -e "\033[32m[3/3] 批量重启远程主机（使配置永久生效）...\033[0m"
# read -p "确认重启所有主机？(y/N) " confirm
# if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
#     for h in $HOST_LIST; do
#         if ssh -o ConnectTimeout=5 -o BatchMode=yes "$h" "echo >/dev/null 2>&1"; then
#             echo -e "正在重启主机 $h..."
#             ssh "$h" "reboot" &  # 后台执行，避免阻塞
#         else
#             echo -e "\033[33m警告：主机 $h SSH登录失败，跳过重启！\033[0m"
#         fi
#     done
#     echo -e "所有可连通主机已触发重启，请等待重启完成！"
# else
#     echo -e "已取消重启操作，配置已通过sysctl -p临时生效，重启后永久生效！"
# fi

echo -e "\033[32m===================== 脚本执行完成 =====================\033[0m"

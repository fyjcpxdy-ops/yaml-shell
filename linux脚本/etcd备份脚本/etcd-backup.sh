#!/bin/bash

# 日志处理函数
log() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local message="$1"
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# 错误处理函数
error_exit() {
    log "错误：$1"
    exit 1
}

# 检查是否以root用户运行
if [ "$(whoami)" != "root" ]; then
    log "错误：必须以root用户运行此脚本！" 
    exit 1
fi

# 定义日志文件路径
LOG_DIR="/var/log/etcd-backup"
LOG_FILE="${LOG_DIR}/messages"

# 确保日志目录和文件存在
if [ ! -d "$LOG_DIR" ]; then
    log "目录 $LOG_DIR 不存在，正在创建..."
    mkdir -p "$LOG_DIR" || { log "无法创建日志目录 $LOG_DIR"; exit 1; }
    touch "$LOG_FILE" || { log "无法创建日志文件 $LOG_FILE"; exit 1; }
elif [ ! -f "$LOG_FILE" ]; then
    log "文件 $LOG_FILE 不存在，正在创建..."
    touch "$LOG_FILE" || { log "无法创建日志文件 $LOG_FILE"; exit 1; }
fi

log "开始执行etcd备份脚本"

# 检查依赖命令是否存在
if ! command -v etcdctl &> /dev/null; then
    error_exit "etcdctl 命令未找到，请先安装etcdctl"
fi

# 定义目标目录路径
BACKUP_DIR="/opt/etcd-backups"

# 创建备份目录（如果不存在）
if [ ! -d "$BACKUP_DIR" ]; then
    log "目录 $BACKUP_DIR 不存在，正在创建..."
    mkdir -p "$BACKUP_DIR"
    
    if [ $? -eq 0 ]; then
        log "目录 $BACKUP_DIR 创建成功"
    else
        error_exit "目录 $BACKUP_DIR 创建失败"
    fi
else
    log "目录 $BACKUP_DIR 已存在，无需创建"
fi

# 配置etcd连接参数变量
ETCD_ENDPOINTS="https://127.0.0.1:2379"
ETCD_CACERT="/etc/kubernetes/pki/etcd/ca.crt"
ETCD_CERT="/etc/kubernetes/pki/apiserver-etcd-client.crt"
ETCD_KEY="/etc/kubernetes/pki/apiserver-etcd-client.key"

# 检查etcd证书文件是否存在
if [ ! -f "$ETCD_CACERT" ]; then
    error_exit "CA证书文件 $ETCD_CACERT 不存在"
fi

if [ ! -f "$ETCD_CERT" ]; then
    error_exit "客户端证书文件 $ETCD_CERT 不存在"
fi

if [ ! -f "$ETCD_KEY" ]; then
    error_exit "客户端密钥文件 $ETCD_KEY 不存在"
fi

# 检查etcd连接状态
log "检查etcd连接状态..."
etcdctl --endpoints="${ETCD_ENDPOINTS}" \
  --cacert="${ETCD_CACERT}" \
  --cert="${ETCD_CERT}" \
  --key="${ETCD_KEY}" \
  endpoint health > /dev/null 2>&1

if [ $? -ne 0 ]; then
    error_exit "无法连接到etcd服务器，请检查配置"
fi

# 备份文件路径变量
BACKUP_FILE="${BACKUP_DIR}/etcd-snapshot-$(date +%Y%m%d_%H%M%S).db"

# 执行备份操作
log "开始执行etcd备份..."
etcdctl --endpoints="${ETCD_ENDPOINTS}" \
  --cacert="${ETCD_CACERT}" \
  --cert="${ETCD_CERT}" \
  --key="${ETCD_KEY}" \
  snapshot save "${BACKUP_FILE}"

# 检查备份命令执行结果
if [ $? -ne 0 ]; then
    error_exit "etcd备份命令执行失败"
fi

# 验证备份文件是否存在且不为空
if [ ! -f "$BACKUP_FILE" ]; then
    error_exit "备份文件 $BACKUP_FILE 未创建"
fi

if [ $(stat -c%s "$BACKUP_FILE") -lt 1024 ]; then
    error_exit "备份文件 $BACKUP_FILE 过小，可能不完整"
fi

# 验证备份文件有效性
log "验证备份文件有效性..."
# 执行快照状态检查并捕获输出
SNAPSHOT_STATUS=$(etcdctl snapshot status "${BACKUP_FILE}" 2>&1)
STATUS_EXIT_CODE=$?

if [ $STATUS_EXIT_CODE -ne 0 ]; then
    error_exit "备份文件 $BACKUP_FILE 无效，错误信息: $SNAPSHOT_STATUS"
else
    # 提取关键信息用于显示，移除版本信息
    FILE_NAME=$(basename "$BACKUP_FILE")  # 提取文件名
    
    # 尝试从snapshot status获取文件大小，如果失败则使用du命令
    DB_SIZE=$(echo "$SNAPSHOT_STATUS" | grep -oP 'DB Size:\s+\K.+' | awk '{print $1 " " $2}')
    if [ -z "$DB_SIZE" ]; then
        # 使用du命令获取文件大小，以人类可读格式显示
        DB_SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')
    fi
    
    log "备份文件验证成功！"
    # 按要求格式显示信息，每个属性单独一行
    echo "[$(date +%Y%m%d_%H%M%S)] 文件名: $FILE_NAME" | tee -a "$LOG_FILE"
    echo "[$(date +%Y%m%d_%H%M%S)] 文件大小: $DB_SIZE" | tee -a "$LOG_FILE"
    echo "[$(date +%Y%m%d_%H%M%S)] 文件的绝对路径: $BACKUP_FILE" | tee -a "$LOG_FILE"
fi

# 移除了"备份成功，文件路径：${BACKUP_FILE}"这行日志输出

# 清理30天前的备份文件
log "开始清理30天前的备份文件..."
find "$BACKUP_DIR" -maxdepth 1 -type f -name "etcd-snapshot-*.db" -mtime +30 -print0 | while IFS= read -r -d '' file; do
    rm -f "$file"
    log "已删除旧备份：$file"
done

# 获取当前脚本的绝对路径
if command -v readlink &> /dev/null; then
    SCRIPT_PATH=$(readlink -f "$0")
elif command -v realpath &> /dev/null; then
    SCRIPT_PATH=$(realpath "$0")
else
    SCRIPT_PATH=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
fi

# 转义特殊字符，确保正则匹配正确
ESCAPED_SCRIPT_PATH=$(printf '%s\n' "$SCRIPT_PATH" | sed 's/[.[\*^$()+?{|]/\\&/g')

# 配置计划任务（每天凌晨2点执行）
log "开始配置计划任务..."

# 精确匹配完整的cron任务行（时间表达式+脚本路径）
CRON_TASK="0 2 * * * $SCRIPT_PATH"
ESCAPED_CRON_TASK="^0 2 \* \* \* $ESCAPED_SCRIPT_PATH$"

# 检查计划任务是否已存在
if crontab -l 2>/dev/null | grep -qE "$ESCAPED_CRON_TASK"; then
    log "计划任务已存在，无需重复添加"
else
    # 添加新的计划任务
    (crontab -l 2>/dev/null; echo "$CRON_TASK") | crontab -
    
    # 检查计划任务是否添加成功
    if [ $? -eq 0 ]; then
        log "计划任务添加成功，每天凌晨2点自动执行备份"
    else
        error_exit "计划任务添加失败"
    fi
fi

log "所有操作完成"


#!/bin/bash
###########################################################################
# 脚本功能：定期记录K8s Pod状态（新增命名空间字段）
# 输出格式：test-cluster|命名空间|Pod名|就绪状态|运行状态|运行时长|Pod IP|运行节点
# 日志目录：/data/pod_info
# 日志命名：zxy-pod-YYYYMMDD_HHMMSS-数据条数.dat（精确到秒+数据条数）
# 计划任务：每分钟执行1次（crontab配置）
###########################################################################

# 配置参数（无需修改）
CLUSTER_NAME="test-cluster"
LOG_DIR="/data/pod_info"
KUBECTL_CMD="kubectl"

# 1. 检查kubectl是否可用
if ! command -v ${KUBECTL_CMD} &> /dev/null; then
    echo "ERROR: 未找到kubectl命令，请确保K8s客户端已安装并配置环境变量"
    exit 1
fi

# 2. 创建日志目录（不存在则自动创建）
if [ ! -d "${LOG_DIR}" ]; then
    mkdir -p "${LOG_DIR}"
    chmod 755 "${LOG_DIR}"
    echo "日志目录已创建：${LOG_DIR}"
fi

# 3. 先执行kubectl命令获取Pod数据（排除表头），并统计数据条数【核心修改1】
# 临时存储Pod数据（避免重复执行kubectl）
POD_DATA=$(${KUBECTL_CMD} get pods -o wide -A 2>/dev/null | awk 'NR > 1')
# 统计数据条数（行数=Pod总数）
DATA_COUNT=$(echo "${POD_DATA}" | wc -l)
# 生成时间戳（精确到秒）
TIME_STAMP=$(date +%Y%m%d_%H%M%S)
# 生成新的文件名：zxy-pod-时间戳-数据条数.dat【核心修改2】
LOG_FILENAME="${LOG_DIR}/zxy-pod-${TIME_STAMP}-${DATA_COUNT}.dat"
# 记录时间（用于控制台提示）
RECORD_TIME=$(date +"%Y-%m-%d %H:%M:%S")

# 4. 写入Pod状态数据到文件
echo "=== 集群：${CLUSTER_NAME} | 记录时间：${RECORD_TIME} | 输出格式：集群名|命名空间|Pod名|就绪状态|运行状态|运行时长|Pod IP|运行节点 ===" > "${LOG_FILENAME}"
echo "${POD_DATA}" | awk -v cluster="${CLUSTER_NAME}" '
    {
        # 字段顺序：集群名|命名空间|Pod名|就绪状态|运行状态|运行时长|Pod IP|运行节点
        printf "%s|%s|%s|%s|%s|%s|%s|%s\n", cluster, $1, $2, $3, $4, $6, $7, $8
    }
' >> "${LOG_FILENAME}"

# 5. 控制台提示（可选）
echo "[$RECORD_TIME] Pod状态已记录至：${LOG_FILENAME}（本次共记录${DATA_COUNT}个Pod）"

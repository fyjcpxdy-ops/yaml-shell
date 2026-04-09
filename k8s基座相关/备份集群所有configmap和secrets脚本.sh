#!/bin/bash
set -euo pipefail  # 开启严格模式，脚本出错立即停止

# ====================== 配置项 ======================
BACKUP_ROOT="/backup/k8s-configs"           # 备份根目录
TIMESTAMP=$(date +%Y%m%d-%H%M%S)            # 备份时间戳
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"    # 本次备份目录
RETENTION_DAYS=7000000                      # 保留备份(天)
# ====================================================

# 颜色输出（可选，方便看日志）
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}开始 K8s ConfigMap + Secret 全量备份${NC}"
echo -e "${GREEN}备份目录: ${BACKUP_DIR}${NC}"
echo -e "${GREEN}============================================${NC}"

# 1. 创建备份根目录
mkdir -p "${BACKUP_DIR}" || { echo -e "${RED}创建备份目录失败！${NC}"; exit 1; }

# 2. 获取集群所有命名空间
ALL_NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
if [ -z "${ALL_NAMESPACES}" ]; then
    echo -e "${RED}获取命名空间失败，请检查 kubectl 连接！${NC}"
    exit 1
fi

# 3. 遍历所有命名空间，逐个备份
for NS in ${ALL_NAMESPACES}; do
    echo -e "\n${GREEN}→ 正在备份命名空间: ${NS}${NC}"

    # 创建该命名空间的备份子目录
    CM_DIR="${BACKUP_DIR}/${NS}/configmaps"
    SEC_DIR="${BACKUP_DIR}/${NS}/secrets"
    mkdir -p "${CM_DIR}" "${SEC_DIR}"

    # ====================== 备份 ConfigMap（每个单独文件） ======================
    echo "  └─ 备份 ConfigMap..."
    # 获取当前 ns 下所有 configmap 名称
    CM_LIST=$(kubectl get configmap -n "${NS}" -o name 2>/dev/null | cut -d'/' -f2)
    for CM in ${CM_LIST}; do
        kubectl get configmap "${CM}" -n "${NS}" -o yaml > "${CM_DIR}/${CM}.yaml"
        echo "    ✔ ${CM}.yaml"
    done

    # ====================== 备份 Secret（每个单独文件） ======================
    echo "  └─ 备份 Secret..."
    # 获取当前 ns 下所有 secret 名称
    SEC_LIST=$(kubectl get secret -n "${NS}" -o name 2>/dev/null | cut -d'/' -f2)
    for SEC in ${SEC_LIST}; do
        kubectl get secret "${SEC}" -n "${NS}" -o yaml > "${SEC_DIR}/${SEC}.yaml"
        echo "    ✔ $SEC}.yaml"
    done
done

# 4. 清理过期备份（删除7天前的目录）
echo -e "\n${GREEN}→ 清理 ${RETENTION_DAYS} 天前的旧备份...${NC}"
find "${BACKUP_ROOT}" -type d -mtime +"${RETENTION_DAYS}" -exec rm -rf {} \; 2>/dev/null

# 完成
echo -e "\n${GREEN}============================================${NC}"
echo -e "${GREEN}✅ 备份完成！所有资源已单独存储${NC}"
echo -e "${GREEN}============================================${NC}"

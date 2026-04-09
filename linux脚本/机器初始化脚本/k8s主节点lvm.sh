#!/bin/bash
# Master节点LVM配置脚本（适配vdc/150G、vdd/150G、vde/200G）
# 用途：vdc→runtime / vdd→kubelet / vde→etcd

# ===================== 第一步：清理旧LVM残留（避免已存在报错） =====================
# 卸载已挂载的目录（若存在）
umount /runtime /kubelet /etcd 2>/dev/null

# 强制删除旧的LV/VG/PV（避免残留导致创建失败）
lvremove -f /dev/vg_runtime/lv_runtime 2>/dev/null
vgremove -f vg_runtime 2>/dev/null
pvremove -f /dev/vdc 2>/dev/null

lvremove -f /dev/vg_kubelet/lv_kubelet 2>/dev/null
vgremove -f vg_kubelet 2>/dev/null
pvremove -f /dev/vdd 2>/dev/null

lvremove -f /dev/vg_etcd/lv_etcd 2>/dev/null
vgremove -f vg_etcd 2>/dev/null
pvremove -f /dev/vde 2>/dev/null

# ===================== 第二步：创建LVM卷组/逻辑卷（替换为实际磁盘） =====================
# 1. vdc(150G) → vg_runtime/lv_runtime（替换原sdb）
pvcreate /dev/vdc && vgcreate vg_runtime /dev/vdc && lvcreate -l 100%VG -n lv_runtime vg_runtime

# 2. vdd(150G) → vg_kubelet/lv_kubelet（替换原sdc）
pvcreate /dev/vdd && vgcreate vg_kubelet /dev/vdd && lvcreate -l 100%VG -n lv_kubelet vg_kubelet

# 3. vde(200G) → vg_etcd/lv_etcd（替换原sdd，200G满足etcd大容量需求）
pvcreate /dev/vde && vgcreate vg_etcd /dev/vde && lvcreate -l 100%VG -n lv_etcd vg_etcd

# ===================== 第三步：格式化逻辑卷（-f强制覆盖，避免数据提示） =====================
mkfs.xfs -f /dev/vg_runtime/lv_runtime
mkfs.xfs -f /dev/vg_kubelet/lv_kubelet
mkfs.xfs -f /dev/vg_etcd/lv_etcd

# ===================== 第四步：创建目录并挂载（修复原脚本etcd挂载笔误） =====================
mkdir -p /runtime /kubelet /etcd
mount /dev/vg_runtime/lv_runtime /runtime
mount /dev/vg_kubelet/lv_kubelet /kubelet
mount /dev/vg_etcd/lv_etcd /etcd  # 修复原脚本错误：vg_kubelet→vg_etcd

# ===================== 第五步：写入fstab（永久挂载，去重+清理多余空格） =====================
# 检查是否已存在，避免重复追加；去掉末尾多余空格，符合fstab规范
grep -q "/dev/vg_runtime/lv_runtime" /etc/fstab || \
  echo "/dev/vg_runtime/lv_runtime /runtime xfs defaults 0 0" >>/etc/fstab
grep -q "/dev/vg_kubelet/lv_kubelet" /etc/fstab || \
  echo "/dev/vg_kubelet/lv_kubelet /kubelet xfs defaults 0 0" >>/etc/fstab
grep -q "/dev/vg_etcd/lv_etcd" /etc/fstab || \
  echo "/dev/vg_etcd/lv_etcd /etcd xfs defaults 0 0" >>/etc/fstab

# ===================== 验证配置结果（直观看到执行效果） =====================
echo -e "\n===== Master节点LVM配置完成！====="
echo "1. 磁盘/LVM信息："
lsblk | grep -E "vdc|vdd|vde|lv_runtime|lv_kubelet|lv_etcd"
echo -e "\n2. 挂载信息："
df -hT | grep -E "/runtime|/kubelet|/etcd"
echo -e "\n3. fstab配置："
grep -E "/runtime|/kubelet|/etcd" /etc/fstab

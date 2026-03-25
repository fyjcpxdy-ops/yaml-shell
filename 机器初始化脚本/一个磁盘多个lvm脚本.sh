#!/bin/bash
# 最简版：给vdb分区并创建LVM，挂载/runtime和/kubelet

# 1. 清除vdb原有分区表（确保干净）
dd if=/dev/zero of=/dev/vdb bs=512 count=1 &>/dev/null
partprobe /dev/vdb

# 2. 免交互给vdb创建分区（vdb1:200G，vdb2:剩余）
# 关键修复：fdisk指令用换行分隔，空行代表回车
fdisk /dev/vdb <<-EOF
n
p
1

+200G
n
p
2


w
EOF

# 3. 刷新分区表，等待生效
partprobe /dev/vdb
sleep 2

# 4. 创建vg_runtime（vdb1）
pvcreate /dev/vdb1 && vgcreate vg_runtime /dev/vdb1 && lvcreate -l 100%VG -n lv_runtime vg_runtime

# 5. 创建vg_kubelet（vdb2）
pvcreate /dev/vdb2 && vgcreate vg_kubelet /dev/vdb2 && lvcreate -l 100%VG -n lv_kubelet vg_kubelet

# 6. 格式化逻辑卷（-f强制覆盖）
mkfs.xfs -f /dev/vg_runtime/lv_runtime
mkfs.xfs -f /dev/vg_kubelet/lv_kubelet

# 7. 创建目录+挂载
mkdir -p /runtime /kubelet
mount /dev/vg_runtime/lv_runtime /runtime
mount /dev/vg_kubelet/lv_kubelet /kubelet

# 8. 写入fstab（永久挂载，去重）
grep -q "/dev/vg_runtime/lv_runtime" /etc/fstab || echo "/dev/vg_runtime/lv_runtime /runtime xfs defaults 0 0" >>/etc/fstab
grep -q "/dev/vg_kubelet/lv_kubelet" /etc/fstab || echo "/dev/vg_kubelet/lv_kubelet /kubelet xfs defaults 0 0" >>/etc/fstab

# 验证（最简输出）
echo -e "\n执行完成！分区/挂载信息："
lsblk /dev/vdb | grep vdb
df -h | grep -E "/runtime|/kubelet"
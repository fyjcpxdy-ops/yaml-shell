pvcreate /dev/vdc && vgcreate vg_runtime /dev/vdc && lvcreate -l 100%VG -n lv_runtime vg_runtime
pvcreate /dev/vdd && vgcreate vg_kubelet /dev/vdd && lvcreate -l 100%VG -n lv_kubelet vg_kubelet
mkfs.xfs -f /dev/vg_runtime/lv_runtime
mkfs.xfs -f /dev/vg_kubelet/lv_kubelet
mkdir -p /runtime
mkdir -p /kubelet
mount /dev/vg_runtime/lv_runtime /runtime
mount /dev/vg_kubelet/lv_kubelet /kubelet
echo "/dev/vg_runtime/lv_runtime /runtime xfs defaults 0 0" >>/etc/fstab
echo "/dev/vg_kubelet/lv_kubelet /kubelet xfs defaults 0 0" >>/etc/fstab

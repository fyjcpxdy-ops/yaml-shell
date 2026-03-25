k8s配置显卡数量

```
kubectl --kubeconfig=/root/.kube/config label nodes muxi moorethreads.com/MetaX-C550=8 --overwrite
```

kubevirt.yaml

```
root@muxi:~# cat kubevirt.yaml 
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
  annotations:
    kubevirt.io/latest-observed-api-version: v1
    kubevirt.io/storage-observed-api-version: v1
spec:
  imagePullPolicy: IfNotPresent
  configuration:
    developerConfiguration:
      featureGates:
        - PCIePassthrough  # PCIe直通必需（已开启）
        - HostDisk
        - HotplugVolumes
        - Snapshot
        - HostDevices      # 主机设备直通基础（已开启）
        - ExternalResource
      useEmulation: false  # 关闭软件模拟，启用KVM硬件加速（已配置）
    permittedHostDevices:
      pciHostDevices:
        # 原有：华为昇腾910B NPU 透传配置（保留，可同时支持）
        - pciVendorSelector: "19e5:d802"  # 昇腾910B的厂商ID:设备ID
          resourceName: "huawei.com/Ascend910"  # 虚拟机引用昇腾设备的名称
          externalResourceProvider: false  # 本地设备（非外部资源）
        
        # 新增：摩尔线程 MetaX C550 GPU 透传配置（核心修改）
        - pciVendorSelector: "9999:4000"  # 摩尔线程的厂商ID:设备ID（替换后的关键字段）
          resourceName: "moorethreads.com/MetaX-C550"  # 虚拟机引用该GPU的名称（自定义，需唯一）
          externalResourceProvider: false  # 本地设备（非外部资源）
  workloadUpdateStrategy: {}
```

npu.yaml

```
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: npu-2
  namespace: default
  annotations:
    kubevirt.io/run-as-non-root: "false"  # 配合 root 运行，无需删除
spec:
  runStrategy: Manual  # 保持手动启动，避免自动重启
  template:
    spec:
      # 虚拟机域配置（保持不变）
      domain:
        cpu:
          cores: 8
          sockets: 1
          threads: 1
        memory:
          guest: "48Gi"
        firmware:
          bootloader:
            bios: {}  # BIOS 启动，兼容 ubuntu 云镜像
        devices:
          disks:
            - name: datavolumedisk
              bootOrder: 1  # 优先启动系统盘（DataVolume）
              disk:
                bus: virtio  # 高性能总线，必须保留
            - name: cloudinitdisk
              disk:
                bus: virtio
          gpus:
            - deviceName: "moorethreads.com/MetaX-C550"
              name: npu-6
            - deviceName: "moorethreads.com/MetaX-C550"
              name: npu-7
          interfaces:
            - name: net1
              bridge: {}  # Pod 网络桥接模式，稳定可靠
      # 网络配置（保持不变）
      networks:
        - name: net1
          pod: {}
      # 存储卷配置（保持不变，已正确关联 DataVolume）
      volumes:
        - name: datavolumedisk
          dataVolume:
            name: amd64-ubuntu-test  # 与就绪的 DataVolume 名称完全一致（无需改）
        - name: cloudinitdisk
          cloudInitNoCloud:
            networkData: |
              version: 2
              ethernets:
                net1:
                  dhcp4: true
                  nameservers:
                    addresses: [8.8.8.8, 8.8.4.4]
            userData: |
              #cloud-config
              hostname: npu-2
              ssh_pwauth: true
              chpasswd:
                expire: false
                list: |
                  root:ubuntu
              users:
                - name: root
                  lock_passwd: false
                  sudo: ALL=(ALL) NOPASSWD:ALL
              write_files:
                - path: /etc/default/grub.d/50-cma.cfg
                  permissions: '0644'
                  content: |
                    GRUB_CMDLINE_LINUX="cma=16Gi console=tty1"
              runcmd:
                - sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
                - systemctl restart ssh
                - update-grub
                  #           - reboot
```


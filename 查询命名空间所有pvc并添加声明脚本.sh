#!/bin/bash

# 检查是否传入命名空间参数
if [ $# -eq 0 ]; then
  echo "Usage: $0 <namespace>"
  echo "Example: $0 logging"
  echo "Example: $0 --all (for all namespaces)"
  exit 1
fi

NAMESPACE="$1"

# 处理所有命名空间的情况
if [ "$NAMESPACE" == "--all" ]; then
  NAMESPACES=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
else
  NAMESPACES="$NAMESPACE"
fi

for NS in $NAMESPACES; do
  echo "Processing namespace: $NS"
  
  # 获取该命名空间下的所有 Pod
  PODS=$(kubectl -n "$NS" get pods -o jsonpath='{.items[*].metadata.name}')
  
  for POD in $PODS; do
    echo "  Processing pod: $POD"
    
    # 获取该 Pod 中所有挂载 PVC 的卷名（过滤掉 ConfigMap/Secret/EmptyDir 等非持久卷）
    VOLUMES=$(kubectl -n "$NS" get pod "$POD" -o json | jq -r '.spec.volumes[] | select(.persistentVolumeClaim != null) | .name' | tr '\n' ',' | sed 's/,$//')
    
    if [ -n "$VOLUMES" ]; then
      echo "    Found PVC volumes: $VOLUMES"
      # 加注解（--overwrite 覆盖已有的错误注解）
      kubectl -n "$NS" annotate pod "$POD" backup.velero.io/backup-volumes="$VOLUMES" --overwrite
      echo "    Annotated successfully"
    else
      echo "    No PVC volumes found, skipping"
    fi
  done
done

echo "Done."
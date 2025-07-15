#!/bin/bash
# 启用GlobalRoute直连
kubectl patch cm tke-service-controller-config -n kube-system \
  --patch '{"data":{"GlobalRouteDirectAccess":"true"}}'

# 创建业务负载
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: real-ip-demo
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: real-ip-container
        image: vickytan-demo.tencentcloudcr.com/kestrelli/images:v1.0 # 替换为您的镜像
        ports:
        - containerPort: 5000 # 业务实际端口
EOF

# 创建直连Service
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: clb-direct-pod
  annotations:
    service.cloud.tencent.com/direct-access: "true" # 直连开关
spec:
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80         # 外部访问端口
      targetPort: 5000 # 业务容器端口
EOF
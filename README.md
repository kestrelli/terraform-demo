
​### 背景

本 Playbook 旨在指导您通过 Kubernetes 的 `VPC-CNI` 网络模式，实现 ​**CLB 直连业务 Pod**​ 的能力，确保业务 Pod 收到的请求源 IP 为客户端真实 IP。本方案完全绕过 NodePort，适用于腾讯云容器服务（TKE）环境。

### 前置条件

1. ​**集群环境**​
	- TKE 集群需启用 `VPC-CNI` 网络模式
	- 确保集群有可用节点且 `kubectl` 已配置访问权限
2. ​**镜像准备**​
	- 已构建业务镜像并推送至腾讯云镜像仓库（个人版/企业版）
	- 示例镜像版本：`vickytan-demo.tencentcloudcr.com/kestrelli/images：v1.0`

### 操作流程

#### Step 1: 创建业务工作负载（Deployment）
​**1.创建 Deployment YAML 文件(deployment.yaml)**​
``` 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: real-ip-demo
  namespace: default
spec:
  replicas: 3  # 按需调整 Pod 数量
  selector:
    matchLabels:
      app: real-ip-app
  template:
    metadata:
      labels:
        app: real-ip-app
    spec:
      containers:
      - name: real-ip-container
        image: vickytan-demo.tencentcloudcr.com/kestrelli/images:v1.0
        ports:
        - containerPort: 5000
```
📌 ​**关键配置**​
- `metadata.labels` 需与后续 Service 选择器匹配
- `containerPort` 需与业务实际端口一致

​**2.部署工作负载**​

``` 
kubectl apply -f deployment.yaml
```

**3.验证 Pod 状态**​

```
kubectl get pods -l app=real-ip-app
```
**预期输出**​：所有 Pod 状态为 `Running`

![截屏2025-07-09 11.26.12.png](/tencent/api/attachments/s3/url?attachmentid=33094690) 
![截屏2025-07-09 12.26.08.png](/tencent/api/attachments/s3/url?attachmentid=33098385) 

####Step 2: 创建直连 Pod 模式的 Service
**1.创建 Service YAML 文件（service.yaml）**​

``` 
apiVersion: v1
kind: Service
metadata:
  name: clb-direct-pod
  annotations:
    service.cloud.tencent.com/direct-access: "true"  # 启用直连 Pod 模式
spec:
  selector:
    app: real-ip-app  # 需匹配 Deployment 的标签
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  type: LoadBalancer
```
⚠️ ​**核心参数说明**​
- `annotations.service.cloud.tencent.com/direct-access: "true"`：启用 CLB 直连 Pod

**2.部署 Service**​
```
kubectl apply -f service.yaml
```
​**3.验证 Service 配置**​
```
kubectl describe svc clb-direct-pod
```
![截屏2025-07-09 14.57.59.png](/tencent/api/attachments/s3/url?attachmentid=33105172) 
**关键检查项**​：
- `Annotations` 包含 `direct-access: true`
![截屏2025-07-09 12.09.55.png](/tencent/api/attachments/s3/url?attachmentid=33097825) 
![截屏2025-07-09 12.10.30.png](/tencent/api/attachments/s3/url?attachmentid=33097849) 

####Step 3: 验证真实源 IP 获取
mac系统在终端/win系统在cmd中输入curl+service公网访问IP（如curl 114.132.191.109）
**预期结果**​：显示的客户端 IP ​**非**节点 IP，而是真实公网 IP
![截屏2025-07-09 12.19.11.png](/tencent/api/attachments/s3/url?attachmentid=33098132) 
或者在浏览器直接输入公网IP(114.132.191.109)
![截屏2025-07-09 12.20.57.png](/tencent/api/attachments/s3/url?attachmentid=33098209) 

### 故障排查


|问题现象|排查方向|
|:-:|:-:|
|Pod 无法连接|1. 检查 `containerPort` 与业务端口是否一致<br>2. 检查 Pod 安全组是否放通|
|源 IP 仍是节点 IP|检查 Service annotation `direct-access=true`|
|CLB 无公网 IP|1. 检查账户余额/带宽限制<br>2. 确认未启用内网 LB|

清理资源
```
kubectl delete svc clb-direct-pod
kubectl delete deploy real-ip-demo
```




## TKE真实源IP获取方案全景指南

### 🧩 五大场景对比


|**场景**|**网络模式**|**连接方式**|**节点类型**|**核心特征**|
|:-:|:-:|:-:|:-:|:-:|
|**场景1**|VPC-CNI|直连|原生节点|direct-access: true + 四层镜像|
|**场景2**|GlobalRouter|直连|原生节点|GlobalRouteDirectAccess=true + 四层镜像|
|**场景3**|VPC-CNI|直连|超级节点|direct-access: true + 自动托管节点，天然支持直连|
|**场景4**|VPC-CNI|非直连|原生节点|type: NodePort + ingress.class: qcloud + 七层镜像|
|**场景5**|GlobalRouter|非直连|原生节点|type: NodePort + ingress.class: qcloud + 七层镜像|

## 🔧 核心配置详解

### 场景1：VPC-CNI直连原生节点（四层服务）​​
```
# 以service.yaml文件配置为例
apiVersion: v1
kind: Service
metadata:
  name: clb-direct-pod
  annotations:
    service.cloud.tencent.com/direct-access: "true"  # 核心直连开关
    service.cloud.tencent.com/loadbalance-type: "OPEN"  # 公网CLB
spec:
  selector:
    app: real-ip-app  # 匹配Deployment标签
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80        # Service端口
      targetPort: 5000 # 业务实际端口（需与Deployment一致）
```

#### 核心特征​
- 通过direct-access: true注解启用CLB直连Pod
- 使用四层镜像​：vickytan-demo.tencentcloudcr.com/kestrelli/images:v1.0
- 源IP通过TCP层remote_addr直接获取

### 场景2：GlobalRouter直连原生节点（四层服务）​​

```
# 以service.yaml文件配置为例
apiVersion: v1
kind: Service
metadata:
  name: clb-direct-pod
  annotations:
    service.cloud.tencent.com/direct-access: "true"  # 直连开关
spec:
  selector:
    app: real-ip-app
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
```
```
前置集群配置（必做）
kubectl patch cm tke-service-controller-config -n kube-system \
  --patch '{"data":{"GlobalRouteDirectAccess":"true"}}'  # 启用全局直连
```

#### 核心特征：​​
- 依赖ConfigMap全局开关 GlobalRouteDirectAccess:"true"
- 使用四层镜像，源IP通过remote_addr直接获取

### 场景3： VPC-CNI直连超级节点（四层服务）

```
# 以service.yaml文件配置为例
apiVersion: v1
kind: Service
metadata:
  name: clb-direct-pod
  annotations:
    service.cloud.tencent.com/direct-access: "true"  # 直连开关
spec:
  selector:
    app: real-ip-app
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
```

#### 核心特征：​​
- ​无需节点SSH操作，超级节点自动托管
- 与场景1配置完全兼容，仅节点类型不同
- 使用四层镜像，源IP通过remote_addr获取

### 场景4：VPC-CNI非直连原生节点（七层服务）​​
```
# 以service.yaml文件配置为例
apiVersion: v1
kind: Service
metadata:
  name: real-ip-service
spec:
  selector:
    app: real-ip-app
  type: NodePort  # 非直连必需
  ports:
    - port: 80
      targetPort: 5000  # 指向Flask业务端口
```

#### 核心特征：​​
- 使用七层镜像​：test-angel01.tencentcloudcr.com/kestrelli/kestrel-seven-real-ip:v1.0
- 通过X-Forwarded-For请求头获取源IP


### 场景5：GlobalRouter非直连原生节点（七层服务）

```
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: real-ip-service
spec:
  selector:
    app: real-ip-app
  type: NodePort  # 非直连必需
  ports:
    - port: 80
      targetPort: 5000
```

#### 核心特征：​​
- 使用七层镜像，通过X-Forwarded-For头传递源IP
- Service类型必须为NodePort

### 配置验证命令​
```
# 检查Service直连注解
kubectl describe svc <SERVICE_NAME> | grep "direct-access"

# 查看Ingress公网IP
kubectl get ingress -n <NAMESPACE> -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 测试源IP（七层服务）
curl http://<CLB_IP>  # 查看返回的X-Forwarded-For头
```

### **故障排查速查表**​


|现象|高频原因|解决方案|
|:-:|:-:|:-:|
|源IP仍是节点IP|直连注解未生效|检查`direct-access: "true"`或ConfigMap开关|
|七层服务返回404|Ingress未配置`qcloud`注解|添加`kubernetes.io/ingress.class: "qcloud"`|
|Pod无法启动|镜像拉取失败|检查镜像地址及仓库权限|
|CLB无公网IP|账户配额不足|检查CLB配额及账户余额|
>​**预置镜像说明**​
- ​**四层服务镜像**​：`vickytan-demo.tencentcloudcr.com/kestrelli/images:v1.0`（直连场景）
- ​**七层服务镜像**​：`test-angel01.tencentcloudcr.com/kestrelli/kestrel-seven-real-ip:v1.0`（非直连场景）

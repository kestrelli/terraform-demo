
## TKE真实源IP获取方案全景指南

### 🧩 五大场景对比


|**场景**|**网络模式**|**连接方式**|**节点类型**|**核心特征**|
|:-:|:-:|:-:|:-:|:-:|
|**场景1**|VPC-CNI|直连|原生节点|direct-access: true |
|**场景2**|GlobalRouter|直连|原生节点|GlobalRouteDirectAccess=true |
|**场景3**|VPC-CNI|直连|超级节点|direct-access: true，天然支持直连|
|**场景4**|VPC-CNI|非直连|原生节点|type: NodePort + ingress.class: qcloud |
|**场景5**|GlobalRouter|非直连|原生节点|type: NodePort + ingress.class: qcloud |

## 🔧 业务场景配置举例说明

### 场景1：VPC-CNI直连pod（原生节点）​​
```
# 以service.yaml文件配置为例
# 核心特征​
# 通过direct-access: true注解启用CLB直连Pod
# 源IP通过TCP层remote_addr直接获取

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



### 场景2：GlobalRouter直连pod（原生节点）​​

```
# 以service.yaml文件配置为例
# 核心特征
# 依赖ConfigMap全局开关 GlobalRouteDirectAccess:"true"
# 源IP通过remote_addr直接获取

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



### 场景3： VPC-CNI直连pod（超级节点）

```
# 以service.yaml文件配置为例
# 核心特征：​​
# ​无需节点SSH操作，超级节点自动托管
# 源IP通过remote_addr获取

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



### 场景4：VPC-CNI非直连pod（原生节点）​​
```
# 以service.yaml文件配置为例
# 核心特征
# 通过X-Forwarded-For请求头获取源IP

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




### 场景5：GlobalRouter非直连pod（原生节点）

```
# 以service.yaml文件配置为例
# 核心特征​​
# 通过X-Forwarded-For头传递源IP
# Service类型必须为NodePort

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


>​**预置镜像说明**​
- ​**四层服务镜像**​：`vickytan-demo.tencentcloudcr.com/kestrelli/images:v1.0`（适用于直连场景）
- ​**七层服务镜像**​：`test-angel01.tencentcloudcr.com/kestrelli/kestrel-seven-real-ip:v1.0`（适用于非直连场景）

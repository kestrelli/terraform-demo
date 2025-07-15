

## TKE真实源IP获取方案全景指南

### 🧩 五大场景对比


|**场景**|**网络模式**|**连接方式**|**节点类型**|**核心特征**|
|:-:|:-:|:-:|:-:|:-:|
|**场景1**|VPC-CNI|直连|原生节点|注解`direct-access: true`|
|**场景2**|GlobalRouter|直连|原生节点|ConfigMap启用`GlobalRouteDirectAccess`|
|**场景3**|VPC-CNI|直连|超级节点|天然支持直连|
|**场景4**|VPC-CNI|非直连|原生节点|需配置X-Forwarded-For头|
|**场景5**|GlobalRouter|非直连|原生节点|需配置X-Forwarded-For头|

## 🔧 核心配置详解

### 场景1：VPC-CNI直连（原生节点）
```
# service.yaml 关键配置
metadata:
  annotations:
    service.cloud.tencent.com/direct-access: "true"  # 直连开关
spec:
  type: LoadBalancer
  ports:
  - targetPort: 5000  # 业务实际端口
```

### 场景2：GlobalRouter直连（原生节点）

```
# 启用集群级直连能力
kubectl patch cm tke-service-controller-config -n kube-system \
  --patch '{"data":{"GlobalRouteDirectAccess":"true"}}'
```

### 场景3：VPC-CNI直连（超级节点）

```
# 特殊限制：不可SSH登录节点
spec:
  template:
    spec:
      nodeSelector:
        node.kubernetes.io/instance-type: SUPER_NODE
```

### 场景4：VPC-CNI非直连
```
# service.yaml
spec:
  type: NodePort  # 非直连必需
```

### 场景5：GlobalRouter非直连

```
# ingress.yaml
metadata:
  annotations:
    kubernetes.io/ingress.class: "qcloud"
spec:
  rules:
  - http:
      paths:
      - backend:
          service:
            name: real-ip-svc
            port: 
              number: 80
```

### ⚙️ 统一验证方法
```
# 获取公网IP
CLB_IP=$(kubectl get svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 测试请求（所有场景通用）
curl -s http://$CLB_IP | jq '.headers | {X-Forwarded-For, X-Real-Ip}'
```

**预期输出**：
```
{
  "X-Forwarded-For": "您的客户端源IP",
  "X-Real-Ip": "您的客户端源IP"
}
```

### 📚 文档映射表

|**场景**|**源文档**|**关键区别点**|
|:-:|:-:|:-:|
|VPC-CNI直连（原生节点）|文档VPC-CNI模式下CLB直连pod获取客户端源IP-Playbook|直连注解+原生节点|
|GlobalRouter直连（原生节点）|文档GlobalRouter模式下CLB直连pod获取客户端源IP-Playbook|ConfigMap全局开关|
|VPC-CNI直连（超级节点）|文档超级节点模式下CLB直连pod获取客户端源IP-Playbook|超级节点生效|
|VPC-CNI非直连（原生节点）|文档VPC-CNI模式下CLB非直连pod获取客户端源IP-Playbook|NodePort端口访问|
|GlobalRouter非直连（原生节点）|文档GlobalRouter模式下CLB非直连pod获取客户端源IP-Playbook|Ingress qcloud注解|

所有方案均通过腾讯云TKE 验证

预构建镜像：
- `vickytan-demo.tencentcloudcr.com/kestrelli/images：v1.0`
- `test-angel01.tencentcloudcr.com/kestrelli/kestrel-seven-real-ip:v1.0`


##背景

在TKE环境中，通过CLB七层负载均衡器获取真实源IP是常见需求。本Playbook详细指导如何**实现CLB非直连业务Pod**的方案，帮助您配置TKE Ingress以正确获取客户端真实源IP。

本指南为简化设计，跳过打相关docker镜像，使用我已推送到腾讯镜像仓库的的Flask镜像 `test-angel01.tencentcloudcr.com/kestrelli/kestrel-seven-real-ip:v1.0`，跳过镜像构建等步骤！

## 前置条件

1. ​**腾讯云账号**​：已开通容器服务(TKE)、云服务器(CVM)、容器镜像服务
2. ​**TKE集群**​：版本≥1.14，已配置好kubectl访问凭证

## 快速开始
####步骤1：创建Deployment
**1.创建自定义命名空间（默认为default，自定义为kestrelli）**
```
kubectl create ns kestrelli
```
**2.创建 Deployment YAML 文件**

已存放在workload.yaml中

📌 ​**关键配置**​
- `metadata.labels` 需与后续 Service 选择器匹配
- `containerPort` 需与业务实际端口一致

**3.部署工作负载**

``` 
kubectl apply -f workload.yaml
```
**4.验证 Pod 状态**

``` 
#命名空间换成自己的
kubectl get pods -l app=kestrelli-real-ip -n kestelli
```
**预期输出**​：✅ 看到2个`Running`状态的Pod

####步骤2：创建Service（NodePort类型）
**1.创建 Service YAML 文件(svc.yaml)**

已存放在svc.yaml中

**2.部署 Service**

``` 
#指定命名空间（不指定为default）
kubectl apply -f svc.yaml -n kestrelli
```
**3.验证 Service 配置**

``` 
#工作负载指定的命名空间（这里为kestrelli）
kubectl describe svc real-ip-svc -n kestrelli
```

**验证**​：

``` 
kubectl get svc real-ip-svc -n kestrelli
```
✅ 查看`PORT(S)`列显示 `80:3xxxx/TCP`（3xxxx为自动分配的节点端口）

####步骤3：创建Ingress（核心配置）
**1.创建 Ingrss YAML 文件（ingress.yaml）**

已存放在ingress.yaml中

**2.部署 Ingress**

``` 
#指定命名空间
kubectl apply -f ingress.yaml  -n kestrelli
```

**3.获取访问地址**​：

``` 
#指定命名空间
kubectl get ingress real-ip-ingress -n kestrelli -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

####步骤4：验证真实源IP
**执行命令**​：

``` 
curl http://<上一步获取的IP> 
```
**预期成功输出**​：
```
{  
  "headers": {  
    "X-Forwarded-For": "您的公网IP",  
    "X-Real-Ip": "您的公网IP"  
  }  
}  
```

####故障排查表
|问题现象|解决方案|
|:-:|:-:|
|`curl`无响应|1. 检查Ingress IP是否正确<br>2. 执行 `kubectl describe ingress real-ip-ingress -n kestrelli（指定的命名空间）` 查看events|
|返回404错误|检查Service名称是否拼写正确（`real-ip-svc`）|
|看到Node IP而非公网IP|确认Ingress注解 `ingressClassName: qcloud` 已配置|
|镜像拉取失败|在集群所在VPC执行：<br>`docker pull test-angel01.tencentcloudcr.com/kestrelli/kestrel-seven-real-ip` 测试网络连通性|
>💡 ​**锦囊**​：所有YAML已通过测试，直接复制粘贴即可运行

## 原理解析

**关键设计**​：
1. 镜像直接处理请求，返回`X-Forwarded-For`和`X-Real-IP`头,获取客户端真实源IP
2. Service的`NodePort`模式自动透传源IP
3. Ingress注解`qcloud`启用腾讯云CLB七层转发

#### 项目概述

此 Terraform 项目用于在腾讯云上部署完整的 TKE（Tencent Kubernetes Engine）集群，包含以下核心组件：
- VPC 网络和双可用区子网（南京1区/3区）
- 安全组规则（开放 SSH 22端口及 API 6443端口）
- 托管式 Kubernetes 集群（VPC-CNI 网络模型）
- 多可用区原生节点池（自动扩缩容）
- Serverless 超级节点池
- 7 种运维组件（日志监控、存储插件等）
- 自动生成 kubeconfig 文件


#### 先决条件

1. ​**腾讯云账号**​
	- 开通 容器服务 TKE
	- 准备 `SecretId` 和 `SecretKey`（需 `QcloudTKEFullAccess` 权限）
2. ​**本地环境**​
	```
	安装 Terraform
	brew install terraform  # macOS
	choco install terraform # Windows
	# 安装腾讯云 CLI (可选)
	pip install tccli
	```


#### 文件结构

```
── main.tf                # 核心基础设施配置
├── outputs.tf             # 输出集群信息
├── providers.tf           # Terraform 插件配置
├── variables.tf           # 可自定义参数
├── deploy.sh              # 一键部署脚本
├── destroy.sh            # 资源清理脚本
└── kubeconfig.yaml        # 自动生成的集群凭证
```

#### 快速开始

1. ​**初始化项目**​
	```
	chmod +x deploy.sh destroy.sh
	```
2. ​**启动部署**​

```
	./deploy.sh
	```脚本将提示输入：
	- `SecretId` / `SecretKey`
	- 区域（默认 `ap-nanjing`）
	- Kubernetes 版本（默认 `1.32.2`）
	- 节点类型（默认 `SA5.MEDIUM4`）
```

3. ​**访问集群**​

```
	kubectl --kubeconfig kubeconfig.yaml get nodes
```


#### 核心配置参数


|变量名|描述|默认值|
|:-:|:-:|:-:|
|`region`|部署区域|`ap-nanjing`|
|`cluster_version`|Kubernetes 版本|`1.32.2`|
|`service_cidr`|Service CIDR 网段|`10.200.0.0/22`|
|`instance_type`|节点机型|`SA5.MEDIUM4` (AMD 计算型)|
>修改默认值：编辑 `variables.tf` 文件


#### 部署资源清单

1. ​**网络**​
	- VPC (`172.18.0.0/16`)
	- 双可用区子网 (`172.18.100.0/24`, `172.18.101.0/24`)
2. ​**集群**​
	- 原生节点池（各可用区 2-6 个节点）
	- Serverless 超级节点池（按需调度）
3. ​**运维组件**​
	```
	tke-hpc-controller  # hpc高性能计算管理
	tke-log-agent       # 日志采集
	cfs/cos             # 文件/对象存储插件
	craned/qgpu         # GPU 加速支持
	qosagent            # 服务质量保障
	```


#### 销毁资源

```
./destroy.sh
```>注意：这将永久删除 VPC/集群/节点等所有资源
```

#### 关键注意事项

1. ​**安全组规则**​
	- 默认开放 `0.0.0.0/0` 的 6443 端口（生产环境建议限制 IP）
2. ​**节点池配置**​
	- 原生节点池使用 `CLOUD_BSSD` 云硬盘（高性能 SSD）
	- 数据盘自动挂载到 `/var/lib/container`
3. ​**依赖顺序**​
![Clipboard_Screenshot_1755084347.png](/tencent/api/attachments/s3/url?attachmentid=34173158)


----
#### 问题排查

- ​**权限错误**​：检查 `SecretId/Key` 是否有效
- ​**资源冲突**​：删除 `.terraform.lock.hcl` 后重试
- ​**API 限流**​：等待 1 分钟后重试部署
- ​**节点未就绪**​：
```
	kubectl --kubeconfig kubeconfig.yaml describe nodes
	```

>建议：首次部署后通过 TKE 控制台 验证资源状态


----
此项目适用于快速搭建生产级 K8s 环境，通过修改 `variables.tf` 可适配不同业务场景（如 GPU 机型、私有网络等）。部署完成后建议立即配置 CAM 访问控制 增强安全性。

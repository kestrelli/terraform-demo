
### 背景

本Playbook专门针对腾讯云容器服务(TKE)集群环境，指导您通过Orca Term终端实现CLB直连Pod模式的配置。

所有操作均在腾讯云Orca Term上执行，确保在TKE集群环境中，业务Pod能够获取客户端真实源IP。

本方案通过GlobalRouter网络模式实现，完全绕过NodePort转发，适用于需要真实客户端IP的应用场景（如安全审计、日志分析）。

### 前置条件

在Orca Term中开始操作前，请确保满足以下条件：
|类别|要求|验证方式|
|:-:|:-:|:-:|
|​**集群环境**​|• TKE集群已创建且启用GlobalRouter网络模式<br>• 集群节点状态正常<br>• kubectl已配置访问权限|• 在TKE控制台确认网络模式<br>• `kubectl get nodes`检查节点状态<br>• `kubectl cluster-info`验证连接|
|​**镜像准备**​|• 业务镜像已推送至腾讯云镜像仓库<br>• 有权限拉取镜像|• 确认镜像地址格式：`<仓库>.tencentcloudcr.com/<命名空间>/<镜像>:<标签>`<br>• 在Orca Term测试：`docker pull <镜像地址>`|
|​**访问权限**​|• Orca Term已绑定集群节点<br>• 拥有操作kubectl的权限<br>• 账户有创建CLB的配额|• 在Orca Term确认节点登录状态<br>• 尝试运行`kubectl get pods`验证权限<br>• 检查腾讯云账号余额和CLB配额|
|​**业务准备**​|• 已知业务服务端口<br>• 准备测试客户端|• 确认Deployment的containerPort<br>• 准备可访问公网的设备（验证用）|

#### 操作流程

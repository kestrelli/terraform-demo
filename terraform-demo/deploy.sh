
#!/bin/bash
set -e

echo "===== TKE Terraform Demo 部署开始 ====="

# 清理旧环境
rm -rf .terraform* terraform.tfstate* kubeconfig.yaml

# 输入凭据
read -p "请输入腾讯云SecretId: " TENCENTCLOUD_SECRET_ID
read -s -p "请输入腾讯云SecretKey: " TENCENTCLOUD_SECRET_KEY
echo

# 可选配置
read -p "请输入区域（默认ap-nanjing）: " REGION
REGION=${REGION:-"ap-nanjing"}
read -p "请输入Kubernetes版本（默认1.32.2）: " CLUSTER_VERSION
CLUSTER_VERSION=${CLUSTER_VERSION:-"1.32.2"}
read -p "请输入节点实例类型（默认SA5.MEDIUM4）: " INSTANCE_TYPE
INSTANCE_TYPE=${INSTANCE_TYPE:-"SA5.MEDIUM4"}

# 初始化Terraform
terraform init

# 创建基础设施
terraform apply -auto-approve \
  -var="tencentcloud_secret_id=$TENCENTCLOUD_SECRET_ID" \
  -var="tencentcloud_secret_key=$TENCENTCLOUD_SECRET_KEY" \
  -var="region=$REGION" \
  -var="cluster_version=$CLUSTER_VERSION" \
  -var="instance_type=$INSTANCE_TYPE"

# 输出部署结果
echo "===== TKE集群部署完成 ====="
echo "集群ID: $(terraform output -raw cluster_id)"
echo "集群名称: $(terraform output -raw cluster_name)"
echo "VPC ID: $(terraform output -raw vpc_id)"
echo "子网ID:"
echo "  Primary: $(terraform output -raw subnet_primary_id)"
echo "  Secondary: $(terraform output -raw subnet_secondary_id)"
echo "kubeconfig文件已生成: kubeconfig.yaml"

echo "使用以下命令访问集群:"
echo "kubectl --kubeconfig kubeconfig.yaml get nodes"
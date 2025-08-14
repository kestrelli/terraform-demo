
#!/bin/bash
set -e

echo "===== 销毁TKE集群 ====="
echo "警告: 这将删除所有相关资源!"

read -p "请输入腾讯云SecretId: " TENCENTCLOUD_SECRET_ID
read -s -p "请输入腾讯云SecretKey: " TENCENTCLOUD_SECRET_KEY
echo

# 设置变量
REGION=${REGION:-"ap-nanjing"}

# 销毁资源
terraform destroy -auto-approve \
  -var="tencentcloud_secret_id=$TENCENTCLOUD_SECRET_ID" \
  -var="tencentcloud_secret_key=$TENCENTCLOUD_SECRET_KEY" \
  -var="region=$REGION"

# 清理本地文件
rm -f kubeconfig.yaml terraform.tfstate* .terraform.lock.hcl

echo "===== 资源已成功清理 ====="
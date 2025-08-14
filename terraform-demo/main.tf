resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# ======== VPC网络配置 ========
resource "tencentcloud_vpc" "main" {
  name       = "tke-demo-vpc-${random_string.suffix.result}"
  cidr_block = "172.18.0.0/16"
  tags = {
    billing = "kestrelli"
    env     = "prod"
    ha      = "enabled"
  }
}

resource "tencentcloud_subnet" "primary" {
  name              = "tke-demo-subnet-nj1"
  vpc_id            = tencentcloud_vpc.main.id
  cidr_block        = "172.18.100.0/24"
  availability_zone = "ap-nanjing-1"
}

resource "tencentcloud_subnet" "secondary" {
  name              = "tke-demo-subnet-nj3"
  vpc_id            = tencentcloud_vpc.main.id
  cidr_block        = "172.18.101.0/24"
  availability_zone = "ap-nanjing-3"
}

# 安全组规则
# ======== 安全组配置 ========
resource "tencentcloud_security_group" "tke_sg" {
  name        = "tke-security-group-${random_string.suffix.result}"
  description = "Security group for TKE clusters"
}

# 替换原有的安全组规则配置
resource "tencentcloud_security_group_rule_set" "rules" {
  security_group_id = tencentcloud_security_group.tke_sg.id

  ingress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"
    protocol    = "TCP"
    port        = "22"
    description = "SSH Access"
  }
  
  ingress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"
    protocol    = "TCP"
    port        = "6443"
    description = "Kubernetes API Access"
  }
  
  egress {
    action      = "ACCEPT"
    cidr_block  = "0.0.0.0/0"
    protocol    = "ALL"
    description = "All Outbound"
  }
}

# ======== TKE集群核心配置 ========
resource "tencentcloud_kubernetes_cluster" "tke_cluster" {
  cluster_name        = "tke-demo-cluster-${random_string.suffix.result}"
  cluster_desc        = "Terraform Demo Cluster"
  cluster_version     = var.cluster_version
  container_runtime   = "containerd"
  vpc_id              = tencentcloud_vpc.main.id
  service_cidr        = var.service_cidr
  cluster_max_service_num = 1024
  cluster_max_pod_num = 256
  cluster_deploy_type = "MANAGED_CLUSTER"
  
  # 网络配置
  network_type         = "VPC-CNI"
  eni_subnet_ids       = [
    tencentcloud_subnet.primary.id,
    tencentcloud_subnet.secondary.id
  ]
  
  # 内网访问
  cluster_intranet          = false
  
  tags = {
    billing = "kestrelli"
    env     = "prod"
    ha      = "enabled"
  }
}

# 集群端点配置
resource "tencentcloud_kubernetes_cluster_endpoint" "cluster_endpoint" {
  cluster_id              = tencentcloud_kubernetes_cluster.tke_cluster.id
  cluster_intranet        = true
  cluster_intranet_subnet_id = tencentcloud_subnet.primary.id
  
  depends_on = [
    tencentcloud_kubernetes_native_node_pool.native_nodepool_nj1,
    tencentcloud_kubernetes_native_node_pool.native_nodepool_nj3,
    tencentcloud_kubernetes_serverless_node_pool.super_nodepool
  ]
}

# ======== 原生节点池 ========
# 南京一区节点池
resource "tencentcloud_kubernetes_native_node_pool" "native_nodepool_nj1" {
  name                = "native-node-pool-nj1"
  cluster_id          = tencentcloud_kubernetes_cluster.tke_cluster.id
  type                = "Native"
  unschedulable       = false
  
  labels {
    name  = "workload-type"
    value = "stable"
  }

  native {
    instance_charge_type = "POSTPAID_BY_HOUR"
    instance_types       = [var.instance_type]
    security_group_ids = [tencentcloud_security_group.tke_sg.id]
    subnet_ids           = [tencentcloud_subnet.primary.id]
    
    key_ids              = ["skey-gigpdrzz"]
    replicas             = 2
    machine_type         = "Native"
    
    scaling {
      min_replicas  = 2
      max_replicas  = 6
      create_policy = "ZoneEquality"
    }
    
    system_disk {
      disk_type = "CLOUD_BSSD"
      disk_size = 100
    }

    data_disks {
      auto_format_and_mount = true
      disk_type             = "CLOUD_BSSD"
      disk_size             = 100
      file_system           = "ext4"
      mount_target          = "/var/lib/container"
    }
  }
  
  lifecycle {
    ignore_changes = [
      native[0].instance_types,
      native[0].system_disk
    ]
  }
}

# 南京三区节点池
resource "tencentcloud_kubernetes_native_node_pool" "native_nodepool_nj3" {
  name                = "native-node-pool-nj3"
  cluster_id          = tencentcloud_kubernetes_cluster.tke_cluster.id
  type                = "Native"
  unschedulable       = false
  
  labels {
    name  = "workload-type"
    value = "stable"
  }

  native {
    instance_charge_type = "POSTPAID_BY_HOUR"
    instance_types       = [var.instance_type]
    security_group_ids = [tencentcloud_security_group.tke_sg.id]
    subnet_ids           = [tencentcloud_subnet.secondary.id]
    
    key_ids              = ["skey-gigpdrzz"]
    replicas             = 2
    machine_type         = "Native"
    
    scaling {
      min_replicas  = 2
      max_replicas  = 6
      create_policy = "ZoneEquality"
    }
    
    system_disk {
      disk_type = "CLOUD_BSSD"
      disk_size = 100
    }

    data_disks {
      auto_format_and_mount = true
      disk_type             = "CLOUD_BSSD"
      disk_size             = 100
      file_system           = "ext4"
      mount_target          = "/var/lib/container"
    }
  }
  
  lifecycle {
    ignore_changes = [
      native[0].instance_types,
      native[0].system_disk
    ]
  }
}

# ======== 超级节点池 ========
resource "tencentcloud_kubernetes_serverless_node_pool" "super_nodepool" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  name       = "tke-demo-supernode"
  security_group_ids = [tencentcloud_security_group.tke_sg.id]
  
  # 主可用区节点
  serverless_nodes {
    display_name = "super-node-1"
    subnet_id    = tencentcloud_subnet.primary.id
  }
  
  # 备用可用区节点
  serverless_nodes {
    display_name = "super-node-2"
    subnet_id    = tencentcloud_subnet.secondary.id
  }
}

# ======== kubeconfig 文件 ========
resource "local_file" "kubeconfig" {
  filename = "${path.module}/kubeconfig.yaml"
  content  = tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint.kube_config_intranet
  
  provisioner "local-exec" {
    command = "sed -i '' $'s/\r//g' ${path.module}/kubeconfig.yaml"
  }
  
  depends_on = [tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint]
}

# ======== 运维组件 ========
resource "tencentcloud_kubernetes_addon" "addon_hpc" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "tke-hpc-controller"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig
  ]
}

resource "tencentcloud_kubernetes_addon" "addon_log_agent" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "tke-log-agent"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig
  ]
}

resource "tencentcloud_kubernetes_addon" "addon_cfs_csi" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "cfs"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig
  ]
}

resource "tencentcloud_kubernetes_addon" "addon_cos_csi" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "cos"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig
  ]
}

resource "tencentcloud_kubernetes_addon" "addon_craned" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "craned"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig
  ]
}

resource "tencentcloud_kubernetes_addon" "addon_qgpu" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "qgpu"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig
  ]
}

resource "tencentcloud_kubernetes_addon" "addon_qos" {
  cluster_id = tencentcloud_kubernetes_cluster.tke_cluster.id
  addon_name = "qosagent"
  
  depends_on = [
    tencentcloud_kubernetes_cluster_endpoint.cluster_endpoint,
    local_file.kubeconfig,
    tencentcloud_kubernetes_addon.addon_craned
  ]
}
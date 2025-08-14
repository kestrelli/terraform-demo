output "cluster_id" {
  value = tencentcloud_kubernetes_cluster.tke_cluster.id
}

output "cluster_name" {
  value = tencentcloud_kubernetes_cluster.tke_cluster.cluster_name
}

output "vpc_id" {
  value = tencentcloud_vpc.main.id
}

output "vpc_name" {
  value = tencentcloud_vpc.main.name
}

output "subnet_primary_id" {
  value = tencentcloud_subnet.primary.id
}

output "subnet_secondary_id" {
  value = tencentcloud_subnet.secondary.id
}

output "kubeconfig_filename" {
  value     = local_file.kubeconfig.filename
  sensitive = true
}

output "native_node_pool_nj1_id" {
  value = tencentcloud_kubernetes_native_node_pool.native_nodepool_nj1.id
}

output "native_node_pool_nj3_id" {
  value = tencentcloud_kubernetes_native_node_pool.native_nodepool_nj3.id
}

output "super_node_pool_id" {
  value = tencentcloud_kubernetes_serverless_node_pool.super_nodepool.id
}

output "all_addons" {
  value = [
    tencentcloud_kubernetes_addon.addon_hpc.id,
    tencentcloud_kubernetes_addon.addon_log_agent.id,
    tencentcloud_kubernetes_addon.addon_cfs_csi.id,
    tencentcloud_kubernetes_addon.addon_cos_csi.id,
    tencentcloud_kubernetes_addon.addon_craned.id,
    tencentcloud_kubernetes_addon.addon_qgpu.id,
    tencentcloud_kubernetes_addon.addon_qos.id
  ]
}
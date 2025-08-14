variable "region" {
  description = "TencentCloud region"
  type        = string
  default     = "ap-nanjing"
}

variable "tencentcloud_secret_id" {
  description = "TencentCloud SecretId"
  type        = string
  sensitive   = true
}

variable "tencentcloud_secret_key" {
  description = "TencentCloud SecretKey"
  type        = string
  sensitive   = true
}

variable "cluster_version" {
  description = "Kubernetes cluster version"
  type        = string
  default     = "1.32.2"
}

variable "service_cidr" {
  description = "Kubernetes service CIDR"
  type        = string
  default     = "10.200.0.0/22"
}

variable "instance_type" {
  description = "Node instance type"
  type        = string
  default     = "SA5.MEDIUM4"
}
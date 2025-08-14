terraform {
  required_providers {
    tencentcloud = {
      source  = "tencentcloudstack/tencentcloud"
      version = ">=1.82.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}

provider "tencentcloud" {
  region     = var.region
  secret_id  = var.tencentcloud_secret_id
  secret_key = var.tencentcloud_secret_key
}

provider "random" {}
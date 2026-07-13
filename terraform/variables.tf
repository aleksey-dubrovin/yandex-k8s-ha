# Обязательные переменные
variable "yandex_cloud_token" {
  description = "OAuth token for Yandex Cloud"
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
}

# Переменные с значениями по умолчанию
variable "zone" {
  description = "Default Yandex Cloud zone"
  default     = "ru-central1-a"
}

variable "zones" {
  description = "List of Yandex Cloud zones for multi-zone deployment"
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d", "ru-central1-e"]
}

variable "network_cidr" {
  description = "CIDR for the VPC network"
  default     = "10.10.0.0/16"
}

variable "image_id" {
  description = "ID of the Ubuntu 22.04 LTS image"
  default     = "fd83vkt13re8v8cdapql" # Ubuntu 22.04 LTS
}

variable "public_ssh_key_path" {
  description = "Path to your public SSH key"
  default     = "~/.ssh/id_rsa.pub"
}

# Параметры ВМ
variable "master_cores" {
  description = "Number of CPU cores for master node"
  default     = 2
}

variable "master_memory" {
  description = "Memory in GB for master node"
  default     = 4
}

variable "worker_cores" {
  description = "Number of CPU cores for worker nodes"
  default     = 2
}

variable "worker_memory" {
  description = "Memory in GB for worker nodes"
  default     = 4
}

variable "worker_count" {
  description = "Number of worker nodes"
  default     = 4
}

variable "disk_size" {
  description = "Disk size in GB for all nodes"
  default     = 30
}

variable "core_fraction" {
  description = "Core fraction for VMs (100 for guaranteed)"
  default     = 50
}

variable "use_preemptible" {
  description = "Whether to use preemptible VMs (saves cost)"
  default     = true
}

# Параметры Cluster Autoscaler
variable "cluster_autoscaler_version" {
  description = "Version of Cluster Autoscaler Helm chart"
  default     = "9.37.0"
}
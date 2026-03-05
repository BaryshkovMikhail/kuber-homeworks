# Секретные переменные (значения в terraform.tfvars)
variable "yandex_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yandex_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "yandex_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

# Публичные переменные
variable "yandex_zone" {
  description = "Yandex Cloud default zone"
  type        = string
  default     = "ru-central1-b"
}

variable "vm_username" {
  description = "Username for VMs"
  type        = string
  default     = "yc-user"
}

variable "master_resources" {
  description = "Resources for master node"
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
  })
  default = {
    cores         = 4
    memory        = 8
    core_fraction = 100
    disk_size     = 30
  }
}

variable "worker_resources" {
  description = "Resources for worker nodes"
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
  })
  default = {
    cores         = 2
    memory        = 4
    core_fraction = 100
    disk_size     = 30
  }
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 4
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
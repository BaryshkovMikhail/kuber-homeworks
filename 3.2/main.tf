# Провайдер Yandex Cloud
provider "yandex" {
  token     = var.yandex_token
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = var.yandex_zone
}

# Получение последней версии Ubuntu 20.04 LTS
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts"
}

# Создание сети
resource "yandex_vpc_network" "k8s_network" {
  name        = "k8s-network"
  description = "Network for Kubernetes cluster"
}

# Создание подсети
resource "yandex_vpc_subnet" "k8s_subnet" {
  name           = "k8s-subnet"
  zone           = var.yandex_zone
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  description    = "Subnet for Kubernetes VMs"
}

# Чтение SSH ключа
locals {
  ssh_public_key = file(var.ssh_public_key_path)
  
  # Cloud-init конфигурация в правильном YAML формате
  cloud_config = <<-EOF
#cloud-config
users:
  - name: ${var.vm_username}
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh-authorized-keys:
      - ${local.ssh_public_key}
runcmd:
  - apt-get update
  - apt-get upgrade -y
  - apt-get install -y curl wget vim git
  - echo "Setup completed for $(hostname)"
EOF
}

# Создание мастер-ноды
resource "yandex_compute_instance" "master" {
  name        = "k8s-master"
  hostname    = "k8s-master"
  zone        = var.yandex_zone
  description = "Kubernetes master node"

  resources {
    cores         = var.master_resources.cores
    memory        = var.master_resources.memory
    core_fraction = var.master_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.master_resources.disk_size
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.k8s_subnet.id
    nat       = true
  }

  metadata = {
    user-data = local.cloud_config
    ssh-keys = "${var.vm_username}:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = false
  }
}

# Создание рабочих нод
resource "yandex_compute_instance" "worker" {
  count       = var.worker_count
  name        = "k8s-worker-${count.index + 1}"
  hostname    = "k8s-worker-${count.index + 1}"
  zone        = var.yandex_zone
  description = "Kubernetes worker node ${count.index + 1}"

  resources {
    cores         = var.worker_resources.cores
    memory        = var.worker_resources.memory
    core_fraction = var.worker_resources.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.worker_resources.disk_size
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.k8s_subnet.id
    nat       = true
  }

  metadata = {
    user-data = local.cloud_config
    ssh-keys = "${var.vm_username}:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = false
  }
}
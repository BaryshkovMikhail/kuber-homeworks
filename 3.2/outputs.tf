# Выходные данные для мастер-ноды
output "master_external_ip" {
  description = "External IP address of master node"
  value       = yandex_compute_instance.master.network_interface[0].nat_ip_address
}

output "master_internal_ip" {
  description = "Internal IP address of master node"
  value       = yandex_compute_instance.master.network_interface[0].ip_address
}

# Выходные данные для рабочих нод
output "worker_external_ips" {
  description = "External IP addresses of worker nodes"
  value       = [for instance in yandex_compute_instance.worker : instance.network_interface[0].nat_ip_address]
}

output "worker_internal_ips" {
  description = "Internal IP addresses of worker nodes"
  value       = [for instance in yandex_compute_instance.worker : instance.network_interface[0].ip_address]
}

# Форматированный вывод для ansible inventory
output "ansible_inventory" {
  description = "Ansible inventory content"
  value = <<-EOF
[master]
${yandex_compute_instance.master.network_interface[0].nat_ip_address} ansible_user=${var.vm_username}

[workers]
%{ for ip in [for instance in yandex_compute_instance.worker : instance.network_interface[0].nat_ip_address] ~}
${ip} ansible_user=${var.vm_username}
%{ endfor ~}

[all:children]
master
workers

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
}

# SSH команды для подключения
output "ssh_commands" {
  description = "SSH commands to connect to nodes"
  value = {
    master = "ssh ${var.vm_username}@${yandex_compute_instance.master.network_interface[0].nat_ip_address}"
    workers = [
      for i, instance in yandex_compute_instance.worker : 
      "ssh ${var.vm_username}@${instance.network_interface[0].nat_ip_address}  # worker-${i + 1}"
    ]
  }
}
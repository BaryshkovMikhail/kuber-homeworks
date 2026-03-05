# templates/inventory.tpl
[master]
${master_ip} ansible_user=${username}

[workers]
%{ for ip in worker_ips ~}
${ip} ansible_user=${username}
%{ endfor ~}

[all:children]
master
workers

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
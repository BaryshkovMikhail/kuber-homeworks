#!/bin/bash
set -e

echo "=== Starting FULL worker node setup ==="
echo "Node: $(hostname)"
echo "Date: $(date)"

# 1. Настройка модулей ядра
echo "Configuring kernel modules..."
cat <<EOL | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOL

sudo modprobe overlay
sudo modprobe br_netfilter

# 2. Настройка параметров сети
echo "Configuring network parameters..."
cat <<EOL | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOL

sudo sysctl --system

# 3. Установка containerd
echo "Installing containerd..."
sudo apt-get update
sudo apt-get install -y containerd

# 4. Настройка containerd
echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# 5. Запуск containerd
echo "Starting containerd..."
sudo systemctl restart containerd
sudo systemctl enable containerd

# 6. Проверка containerd
echo "Checking containerd status..."
sudo systemctl status containerd --no-pager | head -10

# 7. Установка kubeadm (если еще не установлен)
echo "Installing kubeadm..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 8. Проверка установки
echo "=== Installation verification ==="
echo "Containerd: $(containerd --version)"
echo "Kubeadm: $(kubeadm version)"
echo "Kubelet: $(kubelet --version)"

echo "=== Setup completed successfully on $(hostname) ==="

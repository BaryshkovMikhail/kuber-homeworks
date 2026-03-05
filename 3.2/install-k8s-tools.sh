#!/bin/bash
set -e

echo "=== Starting Kubernetes tools installation ==="
echo "Node: $(hostname)"
echo "Date: $(date)"

# Создание директории для ключей
sudo mkdir -p /etc/apt/keyrings

# Удаление старых ключей и списков (если есть)
sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo rm -f /etc/apt/sources.list.d/kubernetes.list

# Загрузка и установка ключа
echo "Downloading Kubernetes signing key..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Установка прав на ключ
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Добавление репозитория
echo "Adding Kubernetes repository..."
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Установка прав на файл репозитория
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

# Обновление списка пакетов
echo "Updating package list..."
sudo apt-get update

# Установка пакетов
echo "Installing kubelet, kubeadm, kubectl..."
sudo apt-get install -y kubelet kubeadm kubectl

# Фиксация версий
sudo apt-mark hold kubelet kubeadm kubectl

# Проверка установки
echo "=== Installation complete ==="
echo "kubeadm version: $(kubeadm version 2>/dev/null || echo 'not installed')"
echo "kubectl version: $(kubectl version --client 2>/dev/null || echo 'not installed')"
echo "kubelet version: $(kubelet --version 2>/dev/null || echo 'not installed')"

# Включение kubelet
sudo systemctl enable --now kubelet
sudo systemctl status kubelet --no-pager

echo "=== Setup finished successfully on $(hostname) ==="

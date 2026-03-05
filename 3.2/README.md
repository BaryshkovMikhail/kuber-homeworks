# Домашнее задание к занятию «Установка Kubernetes» - Барышков Михаил


### Задание 1. Установить кластер k8s с 1 master node

1. Подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды.
2. В качестве CRI — containerd.
3. Запуск etcd производить на мастере.
4. Способ установки выбрать самостоятельно.

## Дополнительные задания (со звёздочкой)

**Настоятельно рекомендуем выполнять все задания под звёздочкой.** Их выполнение поможет глубже разобраться в материале.   
Задания под звёздочкой необязательные к выполнению и не повлияют на получение зачёта по этому домашнему заданию. 

------
### Задание 2*. Установить HA кластер

1. Установить кластер в режиме HA.
2. Использовать нечётное количество Master-node.
3. Для cluster ip использовать keepalived или другой способ.

### Правила приёма работы

1. Домашняя работа оформляется в своем Git-репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl get nodes`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.

----

## Решение 1

1. Развертывание 5 нод: 1 мастер и 4 рабочие ноды решил делать в yandex cloud  через terraform

![img1](img/img1.png)

2. После развертывание мастер-ноды зашел на неё по ssh и установил CRI — containerd

![img2](img/img2.png)

3. Создаем скрипт install-worker-fixed.sh который скпируем на все ноды и запусти его

```bash
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
sudo systemctl status containerd --no-pager | head -15

# 7. Подготовка к установке kubeadm (создаем директорию для ключей)
echo "Preparing for kubeadm installation..."
sudo mkdir -p /etc/apt/keyrings

# 8. Установка kubeadm (исправленная версия без интерактивного режима)
echo "Adding Kubernetes repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 9. Установка kubeadm, kubelet, kubectl
echo "Installing kubelet, kubeadm, kubectl..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 10. Проверка установки
echo "=== Installation verification ==="
echo "Containerd: $(containerd --version | head -1)"
echo "Kubeadm: $(kubeadm version -o short 2>/dev/null || echo 'kubeadm not found')"
echo "Kubelet: $(kubelet --version 2>/dev/null || echo 'kubelet not found')"
echo "Kubectl: $(kubectl version --client -o json 2>/dev/null | jq -r '.clientVersion.gitVersion' 2>/dev/null || echo 'kubectl not found')"

# 11. Запуск kubelet
sudo systemctl enable --now kubelet
sudo systemctl status kubelet --no-pager | head -10

echo "=== Setup completed successfully on $(hostname) ==="
```


4. Получаем список IP всех нод.

![img5](img/img5.png)

5. Копируем скрипт на все ноды

![img6](img/img6.png)

6. Запускаем скрипт на всех нодах

```bash
# Создаем директорию для логов
mkdir -p ~/k8s-logs

# Запускаем скрипт на каждой worker ноде
for ip in $WORKER_IPS; do
  echo "========================================="
  echo "🚀 Setting up worker node: $ip"
  echo "========================================="
  
  echo "----- Worker $ip -----" >> ~/k8s-logs/worker-setup.log
  echo "Date: $(date)" >> ~/k8s-logs/worker-setup.log
  
  # Запускаем скрипт и сохраняем вывод
  ssh -o StrictHostKeyChecking=no yc-user@$ip "bash ~/install-worker-fixed.sh " 2>&1 | tee -a ~/k8s-logs/worker-setup.log
  
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ Worker $ip setup completed successfully"
  else
    echo "❌ Worker $ip setup failed"
  fi
  
  echo "" >> ~/k8s-logs/worker-setup.log
  echo ""
done

echo "All workers setup completed! Log saved to ~/k8s-logs/worker-setup.log"
```

![img7](img/img7.png)

7. Проверка результатов

```bash
# Проверка, что скрипт скопировался на все ноды
for ip in $WORKER_IPS; do
  echo "Checking $ip:"
  ssh yc-user@$ip "ls -la ~/install-worker-fixed.sh "
  echo "---"
done

# Проверка версий на всех worker нодах
echo ""
echo "=== Versions on worker nodes ==="
for ip in $WORKER_IPS; do
  echo "Worker $ip:"
  ssh yc-user@$ip "kubeadm version 2>/dev/null | head -1 || echo 'kubeadm not installed'"
  ssh yc-user@$ip "kubectl version --client 2>/dev/null | head -2 | tail -1 || echo 'kubectl not installed'"
  ssh yc-user@$ip "kubelet --version 2>/dev/null || echo 'kubelet not installed'"
  echo "---"
done
```
![img8](img/img8.png)

8. На мастер ноуде запускаем класте.

```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

![img9](img/img9.png)
![img10](img/img10.png)

9. Присоединение worker нод к кластеру

```bash
for ip in $WORKER_IPS; do
  echo "========================================="
  echo "Joining worker node: $ip"
  echo "========================================="
  
  ssh -o StrictHostKeyChecking=no yc-user@$ip "sudo $JOIN_CMD"
  
  if [ $? -eq 0 ]; then
    echo "✅ Worker $ip joined successfully"
  else
    echo "❌ Worker $ip failed to join"
  fi
  echo ""
done
```
![img11](img/img11.png)

10. Финальная проверка на мастер-ноде

![img12](img/img12.png)
![img13](img/img13.png)

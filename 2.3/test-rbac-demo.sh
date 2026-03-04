#!/bin/bash
echo "==============================================="
echo "    ДЕМОНСТРАЦИЯ RBAC ДЛЯ ПОЛЬЗОВАТЕЛЯ developer"
echo "==============================================="
echo ""
echo "1. Информация о сертификате пользователя:"
openssl x509 -in developer.crt -subject -noout
echo ""
echo "2. Роли и привязки в namespace default:"
microk8s kubectl get role,rolebinding -n default
echo ""
echo "3. Тестирование прав доступа:"
echo ""
echo "   а) Команда: microk8s kubectl get pods --as=developer"
echo "   Результат:"
microk8s kubectl get pods --as=developer
echo ""
echo "   б) Команда: microk8s kubectl get pods --as=developer -o wide"
echo "   Результат:"
microk8s kubectl get pods --as=developer -o wide | head -5
echo ""
echo "   в) Команда: microk8s kubectl get deployments --as=developer"
echo "   Результат (ожидается ошибка):"
microk8s kubectl get deployments --as=developer 2>&1
echo ""
echo "   г) Команда: microk8s kubectl logs <pod> --as=developer --tail=1"
POD=$(microk8s kubectl get pods -o name | head -1)
echo "   Результат для $POD:"
microk8s kubectl logs $POD --as=developer --tail=1 2>&1
echo ""
echo "==============================================="

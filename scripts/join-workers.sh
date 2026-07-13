#!/bin/bash

# IP-адреса ваших worker-нод (из вывода terraform output)
WORKER_IPS=(
  "51.250.9.210"
  "130.193.53.172"
  "158.160.183.61"
  "217.198.168.79"
)

# Команда kubeadm join (из вывода kubeadm init)
JOIN_COMMAND="sudo kubeadm join 10.10.0.24:6443 --token r62t67.2je4zn0owjhc8xzl --discovery-token-ca-cert-hash sha256:a12d5b6457f8c4cf5db2f15243d6d96fc1611e8c06f81094735ea1c034cf7a6d"

# Цикл по всем worker-нодам
for ip in "${WORKER_IPS[@]}"; do
  echo "=== Присоединяю ноду $ip ==="
  ssh -o StrictHostKeyChecking=no ubuntu@$ip -i ~/.ssh/aleksey "$JOIN_COMMAND"
  
  # Проверяем код возврата
  if [ $? -eq 0 ]; then
    echo "Нода $ip успешно присоединена"
  else
    echo "Ошибка при присоединении ноды $ip"
  fi
  echo ""
done
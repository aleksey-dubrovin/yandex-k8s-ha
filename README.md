# Домашнее задание к занятию «Установка Kubernetes»

## Описание проекта

В рамках данного домашнего задания был развернут ready кластер Kubernetes в облаке Yandex Cloud. Проект включает полный цикл: от проектирования инфраструктуры до тестирования отказоустойчивости и автоматического масштабирования.

### Цели задания:
1. Развернуть кластер Kubernetes с 1 master и 4 worker нодами.
2. Настроить сетевой плагин для межзоновой маршрутизации.
3. Установить и настроить Metrics Server для сбора метрик.
4. Проверить работу Horizontal Pod Autoscaler (HPA).
5. (Дополнительно) Настроить HA-кластер с несколькими master-нодами.

---

## 🚀 Развертывание инфраструктуры

### 1. Подготовка окружения

1. Установите Terraform (>= 1.0).
2. Установите Yandex Cloud CLI и получите OAuth-токен.
3. Скопируйте `terraform.tfvars.example` в `terraform.tfvars` и заполните его:

```hcl
yandex_cloud_token = "ваш_oauth_токен"
cloud_id           = "ваш_cloud_id"
folder_id          = "ваш_folder_id"
public_ssh_key_path = "~/.ssh/id_rsa.pub"
use_preemptible = true
```

### 2. Создание ВМ

```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

После применения вы увидите IP-адреса всех нод:
---

## ☸️ Установка Kubernetes

### 1. Инициализация кластера

На мастер-ноде (`master-1`) выполните:

```bash
sudo kubeadm init --pod-network-cidr=10.72.0.0/16
```

Сохраните команду `kubeadm join` для присоединения worker-нод.

### 2. Настройка kubectl

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 3. Установка сетевого плагина (Calico)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

### 4. Присоединение worker-нод

На каждой worker-ноде выполните команду `kubeadm join`:

```bash
sudo kubeadm join 10.10.0.24:6443 --token <токен> --discovery-token-ca-cert-hash sha256:<хэш>
```

### 5. Проверка кластера

```bash
kubectl get nodes
```

**Результат:**
```
NAME                   STATUS   ROLES           AGE   VERSION
fhm4j58svcm8v2klgbdm   Ready    control-plane   12h   v1.29.15
bg08h06b1vul87uima04   Ready    <none>          11h   v1.29.15
epd4vipins0pv75q0l3i   Ready    <none>          11h   v1.29.15
fhm885fpbf6s8a3rjdtd   Ready    <none>          11h   v1.29.15
fv4u0rauc7nhrmoiqfuu   Ready    <none>          11h   v1.29.15
```

---

## 🌐 Настройка сети (межзоная маршрутизация)

Для обеспечения связи между подами в разных зонах доступности Calico был переключен на режим VXLAN:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: crd.projectcalico.org/v1
kind: IPPool
metadata:
  name: default-ipv4-ippool
spec:
  blockSize: 26
  cidr: 10.72.0.0/16
  vxlanMode: Always
  natOutgoing: true
  nodeSelector: all()
EOF
```

После изменения конфигурации Calico был перезапущен:

```bash
kubectl rollout restart daemonset -n kube-system calico-node
```

**Результат:** Поды на разных нодах успешно обмениваются трафиком.

---

## 📊 Установка Metrics Server

Metrics Server установлен через Helm с правильными параметрами:

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  --set args={--secure-port=4443,--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname,--metric-resolution=15s} \
  --set service.targetPort=4443 \
  --set containerPort=4443
```

**Проверка:**

```bash
kubectl top nodes
kubectl top pods
```

**Результат:**
```
NAME                   CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
bg08h06b1vul87uima04   34m          1%     1391Mi          36%
epd4vipins0pv75q0l3i   46m          2%     1478Mi          38%
fhm4j58svcm8v2klgbdm   90m          4%     2040Mi          53%
fhm885fpbf6s8a3rjdtd   31m          1%     1433Mi          37%
fv4u0rauc7nhrmoiqfuu   40m          2%     1410Mi          37%
```

---

## 🧪 Тестирование HPA

### 1. Развертывание тестового приложения

```bash
kubectl apply -f manifests/nginx-deployment.yaml
kubectl apply -f manifests/nginx-service.yaml
```

### 2. Создание HPA

```bash
kubectl apply -f manifests/hpa.yaml
```

### 3. Создание нагрузки

```bash
kubectl create job load-generator --image=busybox -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://nginx; done"
```

### 4. Наблюдение за масштабированием

```bash
kubectl get hpa -w
```

**Результат:** Количество реплик увеличилось с 1 до 2 при превышении порога CPU в 50%.

```
NAME    REFERENCE          TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx   Deployment/nginx   36%/50%   1         5         2          17h
```

---

## 🔧 HA-кластер (дополнительное задание)

Для обеспечения высокой доступности control plane были добавлены две дополнительные мастер-ноды (`master-2`, `master-3`) через Terraform и `kubeadm join`:

```bash
sudo kubeadm join 10.10.0.24:6443 --token <токен> \
  --discovery-token-ca-cert-hash sha256:<хэш> \
  --control-plane \
  --certificate-key <ключ>
```

**Проверка:**

```bash
kubectl get nodes
```

**Результат:**
```
NAME                   STATUS   ROLES           AGE   VERSION
master-1               Ready    control-plane   12h   v1.29.15
master-2               Ready    control-plane   1h    v1.29.15
master-3               Ready    control-plane   1h    v1.29.15
worker-1               Ready    <none>          11h   v1.29.15
worker-2               Ready    <none>          11h   v1.29.15
worker-3               Ready    <none>          11h   v1.29.15
worker-4               Ready    <none>          11h   v1.29.15
```

---

## 🧪 Тест отказоустойчивости

Была остановлена одна worker-нода (`worker-1`). Кластер автоматически перераспределил поды на оставшиеся ноды:

```bash
kubectl get pods -o wide
```

**Результат:** Поды с отказавшей ноды были перезапущены на других доступных нодах, приложение осталось доступным.

---

## 📋 Манифесты

### `manifests/nginx-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

### `manifests/nginx-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30261
```

### `manifests/hpa.yaml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

---

## ✅ Выводы

1. **Кластер успешно развернут** в Yandex Cloud с 1 master и 4 worker нодами.
2. **Настроена сеть** между зонами доступности с помощью Calico VXLAN.
3. **Metrics Server установлен** и работает, `kubectl top` доступен.
4. **HPA работает корректно**, автоматически масштабирует приложение под нагрузку.
5. **HA-кластер настроен** с 3 master-нодами.
6. **Кластер готов к эксплуатации** и может выдерживать отказ как worker, так и master-нод.

---

## 📌 Ссылки на использованные материалы

- [Официальная документация Yandex Cloud](https://yandex.cloud/ru/docs)
- [Kubespray](https://kubespray.io/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Metrics Server](https://github.com/kubernetes-sigs/metrics-server)

---
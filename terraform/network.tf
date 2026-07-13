# Создаем сеть VPC
resource "yandex_vpc_network" "k8s_network" {
  name = "k8s-network"
}

# Создаем подсети во всех трех зонах доступности
resource "yandex_vpc_subnet" "k8s_subnet" {
  for_each       = toset(var.zones)
  name           = "k8s-subnet-${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = [cidrsubnet(var.network_cidr, 8, index(var.zones, each.key))]
}

# Безопасность: правила для внутреннего трафика и доступа
resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  description = "Security group for Kubernetes nodes"
  network_id  = yandex_vpc_network.k8s_network.id

  # SSH доступ
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  # Внутреннее общение узлов Kubernetes (все порты внутри сети)
  ingress {
    protocol       = "ANY"
    description    = "Allow all internal traffic"
    v4_cidr_blocks = [var.network_cidr]
  }

  # Разрешить VXLAN (UDP 4789)
  ingress {
    protocol       = "UDP"
    description    = "VXLAN"
    v4_cidr_blocks = [var.network_cidr]
    port           = 4789
  }
  
  # API Kubernetes (kube-apiserver)
  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  # NodePort-сервисы
  ingress {
    protocol       = "TCP"
    description    = "NodePorts"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  # Полный исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
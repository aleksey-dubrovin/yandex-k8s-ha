# Читаем cloud-init конфигурацию из файла
locals {
  user_data = file("${path.module}/cloud-init.yaml")
}

# Создаем мастер-ноду в первой зоне
resource "yandex_compute_instance" "master" {
  name        = "master-1"
  platform_id = "standard-v3"
  zone        = var.zones[0]

  resources {
    cores         = var.master_cores
    memory        = var.master_memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.k8s_subnet[var.zones[0]].id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys          = "ubuntu:${file(var.public_ssh_key_path)}"
    user-data         = local.user_data
    serial-port-enable = "1"
  }

  scheduling_policy {
    preemptible = var.use_preemptible
  }
}

resource "yandex_compute_instance" "masters" {
  count       = 2
  name        = "master-${count.index + 2}"
  platform_id = "standard-v3"
  zone        = var.zones[count.index + 1]

  resources {
    cores         = var.master_cores
    memory        = var.master_memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.k8s_subnet[var.zones[count.index + 1]].id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys          = "ubuntu:${file(var.public_ssh_key_path)}"
    user-data         = local.user_data
    serial-port-enable = "1"
    hostname          = "master-${count.index + 2}"
  }

  scheduling_policy {
    preemptible = var.use_preemptible
  }
}

# Создаем worker-ноды, распределяя их по всем трем зонам
resource "yandex_compute_instance" "workers" {
  count       = var.worker_count
  name        = "worker-${count.index + 1}"
  platform_id = "standard-v3"
  zone        = var.zones[count.index % length(var.zones)]

  resources {
    cores         = var.worker_cores
    memory        = var.worker_memory
    core_fraction = var.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = var.disk_size
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.k8s_subnet[var.zones[count.index % length(var.zones)]].id
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
    nat                = true
  }

  metadata = {
    ssh-keys          = "ubuntu:${file(var.public_ssh_key_path)}"
    user-data         = local.user_data
    serial-port-enable = "1"
  }

  scheduling_policy {
    preemptible = var.use_preemptible
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    master_ip = yandex_compute_instance.master.network_interface[0].nat_ip_address
    master_private_ip = yandex_compute_instance.master.network_interface[0].ip_address
    worker_ips = yandex_compute_instance.workers[*].network_interface[0].nat_ip_address
    worker_private_ips = yandex_compute_instance.workers[*].network_interface[0].ip_address
    master_ips = yandex_compute_instance.masters[*].network_interface[0].nat_ip_address
    master_private_ips = yandex_compute_instance.masters[*].network_interface[0].ip_address
  })
  filename = "../inventory.ini"
}
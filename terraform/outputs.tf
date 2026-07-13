output "master_ip" {
  value       = yandex_compute_instance.master.network_interface[0].nat_ip_address
  description = "Public IP address of the master node"
}

output "worker_ips" {
  value       = yandex_compute_instance.workers[*].network_interface[0].nat_ip_address
  description = "Public IP addresses of the worker nodes"
}

output "master_private_ip" {
  value       = yandex_compute_instance.master.network_interface[0].ip_address
  description = "Private IP address of the master node"
}

output "worker_private_ips" {
  value       = yandex_compute_instance.workers[*].network_interface[0].ip_address
  description = "Private IP addresses of the worker nodes"
}

output "ssh_commands" {
  value       = formatlist("ssh ubuntu@%s", concat([yandex_compute_instance.master.network_interface[0].nat_ip_address], yandex_compute_instance.workers[*].network_interface[0].nat_ip_address))
  description = "SSH commands for all nodes"
}

output "kubeadm_commands" {
  value       = <<-EOT
    # На мастер-ноде:
    sudo kubeadm init --pod-network-cidr=10.244.0.0/16

    # На каждой worker-ноде (замените на реальную команду из вывода kubeadm init):
    sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
  EOT
  description = "Commands to initialize the cluster"
}
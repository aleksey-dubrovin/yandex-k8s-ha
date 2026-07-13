[all]
master-1 ansible_host=${master_ip} ip=${master_private_ip}
%{ for idx, ip in worker_ips ~}
worker-${idx + 1} ansible_host=${ip} ip=${worker_private_ips[idx]}
%{ endfor ~}
%{ for idx, ip in master_ips ~}
master-${idx + 2} ansible_host=${ip} ip=${master_private_ips[idx]}
%{ endfor ~}

[kube_control_plane]
master-1
%{ for idx, ip in master_ips ~}
master-${idx + 2}
%{ endfor ~}

[etcd]
master-1
%{ for idx, ip in master_ips ~}
master-${idx + 2}
%{ endfor ~}

[kube_node]
master-1
%{ for idx, ip in master_ips ~}
master-${idx + 2}
%{ endfor ~}
%{ for idx, ip in worker_ips ~}
worker-${idx + 1}
%{ endfor ~}

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/aleksey
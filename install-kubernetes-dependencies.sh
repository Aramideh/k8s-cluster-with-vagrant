#!/bin/bash

# fix line endings --> sed -i 's/\r//' setup.sh
kubernetes_version=1.24.1

install_required_packages ()
{
echo 'Start install_required_packages'
systemctl stop firewalld
systemctl disable firewalld
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install net-tools -y
yum install lvm2 -y
yum check-update
echo 'END install_required_packages'
}

 
configure_hosts_file ()
{
echo 'Start configure_hosts_file'  
sudo tee /etc/hosts<<EOF
192.168.1.30 master
192.168.1.31 node-01
192.168.1.32 node-02
EOF
echo 'END configure_hosts_file'
}

disable_swap () 
{
echo 'Start disable_swap'  
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
echo 'END disable_swap'
}

iptables_setup ()
{
echo 'Start iptables_setup'

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
echo 'END iptables_setup'
}

install_docker_runtime ()
{

echo 'Start install_docker_runtime'
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
	
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

mkdir /GSSCLUSTER

sudo tee /etc/docker/daemon.json <<EOF
{
"exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
"data-root": "/GSSCLUSTER/docker",
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl daemon-reload
sudo systemctl restart docker
echo 'END install_docker_runtime'
}



install_kubeadm ()
{
echo 'END install_kubeadm'
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

mv /etc/containerd/config.toml /etc/containerd/config.toml.bak
systemctl restart containerd


sudo yum install -y kubelet-$kubernetes_version kubeadm-$kubernetes_version kubectl-$kubernetes_version --disableexcludes=kubernetes

sudo systemctl enable kubelet

kubeadm config images pull --kubernetes-version $kubernetes_version
echo 'END install_kubeadm'
}

 
install_required_packages
install_docker_runtime
configure_hosts_file
disable_swap
iptables_setup
install_kubeadm
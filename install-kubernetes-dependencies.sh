#!/bin/bash


install_required_packages ()
{
systemctl stop firewalld
systemctl disable firewalld
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
yum install net-tools -y
yum install lvm2 -y
yum check-update
cd ~
}

 
configure_hosts_file ()
{
sudo tee /etc/hosts<<EOF
192.168.1.30 master
192.168.1.31 node-01
EOF
}

disable_swap () 
{
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
}

iptables_setup ()
{
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
}

install_docker_runtime ()
{
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
}

 

set_aliases ()
{
 echo 'k=kubectl' >> ~/.bashrc
 echo 'gap=kubectl get pods -A' >> ~/.bashrc
 echo 'wgap=watch -n 1 kuectl get pods -A' >> ~/.bashrc
 echo 'ggp=kubectl get pods -n gss-prod' >> ~/.bashrc
}
  


 
install_required_packages
configure_hosts_file
disable_swap
iptables_setup
install_docker_runtime
set_aliases
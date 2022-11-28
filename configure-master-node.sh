#!/bin/bash

master_node=192.168.1.30
kubernetes_version=1.21.1
pod_network_cidr=10.0.0.0/21

initialize_master_node ()
{

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

sudo yum install -y kubelet-$kubernetes_version kubeadm-$kubernetes_version kubectl-$kubernetes_version --disableexcludes=kubernetes

sudo systemctl enable kubelet
sudo kubeadm init --apiserver-advertise-address=$master_node --pod-network-cidr=$pod_network_cidr --kubernetes-version $kubernetes_version
}


post_bootstraping_actions () 
{
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

##For vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown 900:900 /home/vagrant/.kube/config
}

install_network_cni ()
{
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
}

create_join_command ()
{
kubeadm token create --print-join-command | tee /vagrant/join_command.sh
chmod +x /vagrant/join_command.sh
}


initialize_master_node
post_bootstraping_actions
install_network_cni
create_join_command
#!/bin/bash

master_node=192.168.1.30
kubernetes_version=1.21.1
pod_network_cidr=10.0.0.0/21

bootstrap_kubernetes ()
{
echo 'Start bootstrap_kubernetes'        
sudo kubeadm init --apiserver-advertise-address=$master_node --pod-network-cidr=$pod_network_cidr --kubernetes-version $kubernetes_version
echo 'END bootstrap_kubernetes'
}

install_network_cni ()
{
echo 'Start install_network_cni'        
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
echo 'END install_network_cni'
}


post_bootstraping_actions () 
{
echo 'Start post_bootstraping_actions'        
mkdir -p $HOME/.kube
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

##For vagrant user
mkdir -p /home/vagrant/.kube
sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown 900:900 /home/vagrant/.kube/config
echo 'END post_bootstraping_actions'
}


create_join_command ()
{
echo 'Start create_join_command'        
kubeadm token create --print-join-command | tee /vagrant/join_command.sh
chmod +x /vagrant/join_command.sh
echo 'END create_join_command'
}


bootstrap_kubernetes
post_bootstraping_actions
install_network_cni
create_join_command
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

 


setup_ssh ()
{
mkdir -m 755 ~/.ssh

sudo tee ~/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDN+0uwLtxQx/pWTit65cFRWITYBW9/LDBazn9X3A1aJinN4ibK1qk2yVeBU9wUx+k0+MTMoJUsrZPw8JnpIc0SvFvLh4G7QWMpZR5EMwDmmsN06N0XB8FQ+KeyrVXtEjI7UCDarXly/37RkqWbC9dGX0EU0hscyTjg6W5gWKH1Om5Pfx9G+cSsHZdjtsl9k4RdWBSfuWyEqW9oTdLGryBKrxvP9eFv7AeWFblwWnsEiWg55EW+jPSMl5yQomlrlec3Mgy/vdyYAhNrEXFKQr7loc7/RbnQrUJ20NS9WEjBFLXaqRhEPC/dPiGGTngcIH5Z5BNEr2+4crf7/PBOuuXQQ5Jh9DuBdfOqNQoaud91SwrGQvNSW6SHVg2LlfbBsM5QmHsqQ5zXwjqIAiyjCSU/MD07cqAhYAs56FQ+4zq+d2TfJ672ejnILxE5xktwfgNHC1FivvQHPw3D/Z5Y2HMTm5eYp7Tfm1hWMF+E20JFrAytfYCrQf/bsjwoENTv8ak= sadegh.a@gmail.com
EOF
 echo '# Setup SSH for K8S Cluster' >> /etc/ssh/sshd_config
 echo 'PubKeyAuthentication yes' >> /etc/ssh/sshd_config
 echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
 echo 'ChallengeResponseAuthentication yes' >> /etc/ssh/sshd_config
 systemctl restart sshd.service
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
#setup_ssh
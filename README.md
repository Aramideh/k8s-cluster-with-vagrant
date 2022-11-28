# Bootstraping-Kubernetes-cluster-with-vagrant


Bootstraping Kubernetes Cluster with Vagrant


### Getting Started

1. clone the repository
2. install virtual box
3. install vagrant
4. use command --> vagrant up 

After running vagrant up command in the terminal, the k8s cluster should start bootstraping.

The cluster include one master node and 2 worker nodes.

```
master , node-01 and node-02
```

You can ssh to any node using
```
vagrant ssh "NODE_NAME"
```


for example 
```
vagrant ssh master
```

### Note
The initial codes was copied from [*Ugur Akgül*](https://ugurakgul.medium.com/creating-a-local-kubernetes-cluster-with-vagrant-ba591ab70ee2) , but it has been heavily modified for Centos rather than Ubuntu.

### Authors
* [**Sadeq Aramideh**](https://github.com/Aramideh)


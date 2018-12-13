# ETKhub; JupyterHub for ETK

Documentation for setup, configuration, and administration of 
https://etkhub.ndslabs.org. This is an Ubuntu-based Kubernetes
installation running the JupyterHub Helm chart with Github
authentication and a custom user whitelist.


## VM Setup

ETKhub is hosted on Nebula OpenStack.  The current VM has the 
following configuration:
* Name: etkhub
* Flavor: m1.large
* OS: Ubuntu 16.04


## Kubernetes

Kubernetes was deployed using `kubeadm-bootstrap` which provides
a simple approach to manually scaling Kubernetes clusters using 
virtual machines.  Kubernetes was installed as follows:

```
git clone https://github.com/nds-org/kubeadm-bootstrap
cd kubeadm-bootstrap

sudo ./install-kubeadm.bash
sudo -E ./init-master.bash
```

## Updateing helm

The 0.7 version of JupyterHub requires a newer version of helm than is installed by default. To fix run

```
curl https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz | tar xvz
sudo mv linux-amd64/helm /usr/local/bin
sudo helm init --upgrade
```

## Let's Encrypt

SSL certificates are automatically managed using `kube-lego` and Let's Encrypt. 

```
sudo helm install --name lego stable/kube-lego \
     --namespace=support --set config.LEGO_EMAIL=<your email> \
     --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory
```

## JupyterHub

The JupyterHub deployment uses the [Zero-to-JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/)
Helm chart to deploy JupyterHub on Kuberetes. 

```
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
sudo helm repo update
sudo helm install jupyterhub/jupyterhub  --version=v0.7 \
     --name=etkhub --namespace=etkhub -f config.yaml
```

The [config.yaml](config.yaml) is mostly boilerplate, except for the following:
* `cull.timeout` set to 4 days
* Custom `check_whitelist` method performs lookup on `users.txt`
* Memory and CPU limits 
* No persistent storage


## Whitelist

Dynamic whitelists are not supported out-of-the-box with JupyterHub. We've 
implemented a simple approach serving a `users.txt` file via an Nginx webserver 
that is checked by the `check_whitelist` method.

[nginx.yaml](nging.yaml):
```
kubectl create -f nginx.yaml  -n etkhub
```

## Managing whitelisted users

To add/remove users to the whitelist, simply SSH to the VM and edit 
`whitelist/users.txt`.

## Changing the config.yaml

If you make changes to the `config.yaml`, you'll need to restart.

```
sudo helm upgrade --install hub jupyterhub/jupyterhub   --namespace hub    --version 0.7.0   --values config.yaml
```

`config.yaml` contains __secrets__ and the version in the repository does not hold those secrets (for obvious reasons), so you need to back up and merge with the version currently present in the VM.

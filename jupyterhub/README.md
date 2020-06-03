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


## Prelims
```
sudo apt-get install curl git
# some packages cannot be verified
echo 'APT::Get::AllowUnauthenticated "yes";' |  sudo tee /etc/apt/apt.conf.d/99unauthenticated
# no swap allowed
sudo swapoff --all
sudo sed -i 's/^UUID=.*swap/#&/' /etc/fstab
```

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

## Updating kubernetes

This must not be done via `apt-get` but instead via `kubeadm upgrade`. If
apt-get is used then errors like
https://github.com/kubernetes/kubernetes/issues/65863 are likely to happen. Best
to hold `kubelet`, `kubeadm` and `kubernetes-cni`.

## Updateing helm

The 0.7 version of JupyterHub requires a newer version of helm than is installed by default. To fix run

```
curl https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz | tar xvz
sudo mv linux-amd64/helm /usr/local/bin
sudo helm init --upgrade
# Wait for tiller to be ready!
kubectl rollout status --namespace=kube-system deployment/tiller-deploy --watch
```

## Let's Encrypt

SSL certificates are automatically managed using `kube-lego` and Let's Encrypt. 

```
sudo kubectl create clusterrolebinding add-on-cluster-admin \
     --clusterrole=cluster-admin --serviceaccount=support:default

sudo helm install --name lego stable/kube-lego \
     --namespace=support --set config.LEGO_EMAIL=<your email> \
     --set config.LEGO_URL=https://acme-v01.api.letsencrypt.org/directory
```

*Note* Ensure that there is not expired certificate in ekthub/secrets:
```
kubectl get secrets --namespace etkhub
```
otherwise kube-lego will not be able to renew it b/c nginx-ingress 0.10.2 will
redirect the website that lego checks to https which then fails. Having no
certificate at all avoids the redirect.
```
kubectl delete secret --namespace etkhub kubelego-tls-jupyterhub
```
gets rid of the offending certificate.

## Kubernetes client / server certificates
Kubernetes internal certs are good for a year after which things fail with:

```
Unable to connect to the server: x509: certificate has expired or is not yet valid.
```

To fix this one needs to regenerate the certs in `/etc/kubernetes/pki` follow
[IBM's notes](https://www.ibm.com/support/knowledgecenter/en/SSCKRH_1.0.3/platform/t_certificate_renewal.html).

1. Remove the existing certificate and key files:

```
rm /etc/kubernetes/pki/apiserver.key
rm /etc/kubernetes/pki/apiserver.crt
rm /etc/kubernetes/pki/apiserver-kubelet-client.crt
rm /etc/kubernetes/pki/apiserver-kubelet-client.key
rm /etc/kubernetes/pki/front-proxy-client.crt
rm /etc/kubernetes/pki/front-proxy-client.key
```

2. Create new certificates:

```
kubeadm --config /root/kubeadm.yaml alpha phase certs apiserver --apiserver-advertise-address 127.0.0.1
kubeadm --config /root/kubeadm.yaml alpha phase certs apiserver-kubelet-client
kubeadm --config /root/kubeadm.yaml alpha phase certs front-proxy-client
```

3. regenerate config files

```
kubeadm alpha phase kubeconfig all
cp /etc/kubernetes/admin.conf ~ubuntu/.kube/config
chown ubuntu ~ubuntu/.kube/config
```

4. Reboot node:

```
sudo shutdown -r now
```

### NFS Volume Provisioner
For persistent storage, JupyterHub uses Kubernetes [dynamic volume provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/).  For ETKhub, we are using the [NFS provisioner](https://github.com/kubernetes-incubator/nfs-provisioner) based on configuration files from the [kubeadmin-terraform](https://github.com/nds-org/kubeadm-terraform/blob/master/assets/nfs) repo.  There are alternatives, including a `hostPath` provisioner for a single-node instance. The NFS provisioner is preferred if the cluster will be scaled up to more than one node.

You'll need the `nfs-common` package installed and to restart the `kubelet`:
```
sudo apt-get install nfs-common
sudo systemctl restart kubelet
```

Then, using the [kubeadmin-terraform](https://github.com/nds-org/kubeadm-terraform/blob/master/assets/nfs) templates:

```
cd $HOME
git clone --recursive https://github.com/nds-org/jupyter-et
cd jupyter-et/jupyterhub
cd kubeadm-terraform/assets/nfs
kubectl create -f deployment.yaml -f rbac.yaml  -f storageclass.yaml
```

Note that the storageclass name will need to match the storage clas name specified in the JupyterHub config below.

## JupyterHub configuration

Clone this repository, and create a directory /home/ubuntu/jupyterhub, then create a
secrets.yaml file and link the repository's templates into the new direcotry

```
cd $HOME
mkdir jupyterhub
cd jupyterhub
cat >secrets.yaml <<EOF
hub:
  cookieSecret: "$(openssl rand -hex 32)"
proxy:
  secretToken: "$(openssl rand -hex 32)"
# get these from https://cilogon.org/oauth2/register
auth:
  cilogon:
    clientId: "$CLIENT_ID"
    clientSecret: "$CLIENT_SECRET"
EOF
ln -s ../jupyter-et/jupyterhub/templates ./
ln -s ../jupyter-et/jupyterhub/*.yaml ./
```

## JupyterHub

The JupyterHub deployment uses the [Zero-to-JupyterHub](https://zero-to-jupyterhub.readthedocs.io/en/latest/)
Helm chart to deploy JupyterHub on Kuberetes. 

```
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
sudo helm repo update
sudo helm install jupyterhub/jupyterhub  --version=v0.7 \
     --name=etkhub --namespace=etkhub -f config.yaml -f secrets.yaml 
```

The [config.yaml](config.yaml) is mostly boilerplate, except for the following:
* `cull.timeout` set to 4 days
* Custom `check_whitelist` method performs lookup on `users.txt`
* Memory and CPU limits 
* NSF provisioner for Hub
* No persistent storage for single-user images


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

## Creating teh Docker image

Building the Docker image is too slow to do on demand, so it must be built explicitly

```
cd $HOME/jupter-et
sudo docker build -t ndslabs/jupyter-et .
```

## Changing the config.yaml

If you make changes to the `config.yaml`, you'll need to restart.

```
sudo helm upgrade --install etkhub jupyterhub/jupyterhub etkhub --version 0.7.0 \
     --namespace --values config.yaml \
     --set-string auth.cilogon.clientId=$CLIENTID \
     --set-string auth.cilogon.clientSecret=$CLIENTSECRET \
     --set-string hub.cookieSecret=$COOKIESECRET \
     --set-string proxy.secretToken=$SECRETTOKEN
```

`config.yaml` contains __secrets__ and the version in the repository does not hold those secrets (for obvious reasons), so you need to back up and merge with the version currently present in the VM.

## Gettting information

There are a number of kubernetes namespaces involvded `support`, `etkhub` where `support` contains the letsencrypt containers and `etkhub` the actual jupyterhub containers.

Pods in a namespace are listed via `kubectl get pods --namespace etkhub` and logs for a pod obtained via `kubectl logs --namespace hub-56c69d98d8-5d5x5`. Using `kubctl describe pod --namespace etkhub hub-56c69d98d8-5d5x5` reveal what is going on with the pod and if eg. is waiting for something to happen.

# Kubernetes cluster on AWS

## Description
This is a simple project that can help you install and configure a Kubernetes cluster on AWS Cloud using Cloudformation and [Terraform](https://www.terraform.io/).

## Creating resources on AWS

### Cloudformation

Log in to the AWS Management Console, select Cloudformation in the Services Menu and create a new stack. On Specify template page, choose the file [iam-terraform-user](cloudformation/iam-terraform-user.yaml). After create the stack, go to Outputs tab and copy the values: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```bash
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export AWS_DEFAULT_REGION="us-west-2"
```
Generating a new SSH key to connect on EC2 instance
```bash
ssh-keygen -t rsa -f "k8s-aws-tf-key" -C ""
chmod 400 k8s-aws-tf-key k8s-aws-tf-key.pub
```
Exporting the Terraform's variables with SSH public key 
```bash
export TF_VAR_ssh_public_key=$(cat k8s-aws-tf-key.pub)
export TF_VAR_ssh_key_name=kp-k8s-aws-tf
```

### Terraform

Check the [Terraform variables file](variables.tf) and change the values. Now we need initialize the Terraform on your local machine
```bash
terraform init
```
Creating the resources needed on AWS with Terraform
```bash
# Check all resources that will be created
terraform plan

# If it's ok, create the resources
terraform apply -auto-approve
```

### Connect to your instances

Add the private key into the SSH authentication
```bash
$ ssh-add k8s-aws-tf-key
```
Connect on your instances
```bash
$ ssh -A ubuntu@<Copy the instances public ips from Terraform output>
``` 

## Creating the Kubernetes cluster

### Installing components

Run the bellow commands in **ALL master and worker nodes**

```
# Install Docker
$ curl -fsSL https://get.docker.com | bash

# Install Kubernetes
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
$ echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
$ apt update
$ apt install kubelet kubeadm kubectl -y

# Change the cgroup drive to systemd
$ cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

$ mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
$ systemctl daemon-reload
$ systemctl restart docker
```

### Starting the cluster

Run the bellow commands in **master nodes ONLY**. First we need make download of [kubernetes components](https://kubernetes.io/docs/concepts/overview/components/) (for example: kube-apiserver, kube-scheduler, etcd, coredns, etc)
```bash
$ kubeadm config images pull
```
If you are using instances with 1 CPU, like the free tier instance (t2.micro), you should init the cluster with the flag **--ignore-preflight-errors**
```bash
# instances with 1 CPU
$ kubeadm init --ignore-preflight-errors=NumCPU
# instances with more than 1 CPU
$ kubeadm init
```
Configure the [kubeconfig file](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) that kubectl looks to find the information about the cluster
```bash
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Installing [pod network](https://kubernetes.io/docs/concepts/cluster-administration/addons/) that is required to pod communication cross-nodes. In this case we will install the Weave.
```bash
$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

### Adding new nodes

On **Master node** run the bellow command to print the full 'kubeadm join' flag needed to join the cluster
```bash
$ kubeadm token create --print-join-command
```
Copy the output ('kubeadm join ...' command) e run it into yours **Worker nodes**. Now you can check if the new node already join the cluster:
```bash
$ kubectl get nodes
```

## Deploying my first pod

```bash
kubectl run --image=nginx --port 80
kubectl expose deployment nginx

kubectl expose deployment nginx --type=NodePort
```

## tips

- To know more see the [Kubernetes official docs](https://kubernetes.io/docs)
- Check the [Configuration best practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- Enable the kubectl completion
```bash
$ source <(kubectl completion bash)
```

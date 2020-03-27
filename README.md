## K8s Labs

Creating a Kubernetes cluster on AWS cloud provider with Terraform

### Steps

1. Clone this repository
1. Create a new stack on Cloudformation using the template file: ./cloudformation/iam-terraform-user.yaml
1. Generating a new SSH key to connect on EC2 instance
```bash
ssh-keygen -t rsa -f "k8s-aws-tf-key" -C ""
```
1. Export the Terraform's variables with SSH public key 
```bash
export TF_VAR_ssh_public_key=$(cat k8s-aws-tf-key.pub)
export TF_VAR_ssh_key_name=kp-k8s-aws-tf
```
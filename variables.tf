#### CHECK DEFAULT VALUES
variable "project-name" {
  # the project name
  default = "labs-k8s-aws"
}

variable "source-ip-ssh" {
  # set your public ip
  default = "181.221.4.18/32"
}

variable "instance-type" {
  # free tier
  default = "t2.micro"
}

variable "k8s-master" {
  # number of master nodes
  default = "1"
}

variable "k8s-nodes" {
  # number of worker nodes
  default = "2"
}
####

variable "private-key" {
  default = "./k8s-aws-tf-key"
}

variable "network-cidr" {
  default = "199"
}

variable "public-subnets" {
  type    = list
  default = ["10.199.0.0/20", "10.199.16.0/20", "10.199.32.0/20"]
}

variable "public-cidr-block-in" {
  default = "0.0.0.0/0"
}

# defined with TF_VAR_
variable "ssh_key_name" {
}

variable "ssh_public_key" {
}

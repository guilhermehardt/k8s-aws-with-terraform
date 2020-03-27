variable "project-name" {
  default = "aws-labs"
}

variable "network-cidr" {
  default = "199"
}

variable "public-subnets" {
  type    = list
  default = ["10.199.0.0/20", "10.199.32.0/20"]
}

variable "source-ip-ssh" {
  default = "181.221.4.18/32"
}

data "aws_availability_zones" "available" {
  state = "available"
}

variable "instance-type" {
  # free tier
  default = "t2.micro"
}

variable "k8s-master" {
  default = "1"
}

variable "k8s-nodes" {
  default = "2"
}

variable "public-cidr-block-in" {
  default = "0.0.0.0/0"
}

variable "public-cidr-block-out" {
  default = "0.0.0.0/0"
}

# defined with TF_VAR_
variable "ssh_key_name" {
}

variable "ssh_public_key" {
}

data "aws_ami" "ubuntu-server" {
  # official Cannonical
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


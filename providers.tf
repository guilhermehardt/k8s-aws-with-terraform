#
# Provider Configuration
#

provider "aws" {
  region  = "us-west-2"
  version = ">= 2.49.0"
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

data "aws_availability_zones" "available" {
  state = "available"
}

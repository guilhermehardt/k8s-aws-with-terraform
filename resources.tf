# Master Nodes
resource "aws_instance" "master" {
  count                       = var.k8s-master
  ami                         = data.aws_ami.ubuntu-server.image_id
  instance_type               = var.instance-type
  associate_public_ip_address = true
  subnet_id                   = element(aws_subnet.public-subnets.*.id, count.index)
  key_name                    = aws_key_pair.public-key.key_name
  security_groups             = [aws_security_group.public-sg.id]

  tags = {
    Name    = "k8s-master-${count.index + 1}",
    Project = "${var.project-name}"
  }

  connection {
    private_key = file(var.private-key)
    user        = "ubuntu"
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 15",
      "sudo hostnamectl set-hostname k8s-master-${count.index + 1}",
      "sudo apt-get update -y"
    ]
  }

  depends_on = [aws_vpc.main]
}

# Worker Nodes
resource "aws_instance" "nodes" {
  count                       = var.k8s-nodes
  ami                         = data.aws_ami.ubuntu-server.image_id
  instance_type               = var.instance-type
  associate_public_ip_address = true
  subnet_id                   = element(aws_subnet.public-subnets.*.id, count.index)
  key_name                    = aws_key_pair.public-key.key_name
  security_groups             = [aws_security_group.public-sg.id]

  tags = {
    Name    = "k8s-worker-node-${count.index + 1}",
    Project = "${var.project-name}"
  }

  connection {
    private_key = file(var.private-key)
    user        = "ubuntu"
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sleep 15",
      "sudo hostnamectl set-hostname k8s-worker-node-${count.index + 1}",
      "sudo apt-get update -y"
    ]
  }

  depends_on = [aws_vpc.main]
}

resource "aws_security_group" "public-sg" {
  name        = "${var.project-name}-public-sg"
  description = "Allow ALB traffic"
  vpc_id      = aws_vpc.main.id
}
resource "aws_security_group_rule" "public-sg-ssh-in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.source-ip-ssh]
  security_group_id = aws_security_group.public-sg.id
}
resource "aws_security_group_rule" "public-sg-nodes-in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["10.${var.network-cidr}.0.0/16"]
  security_group_id = aws_security_group.public-sg.id
}
resource "aws_security_group_rule" "public-sg-in-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.public-sg.id
}
resource "aws_security_group_rule" "public-sg-in-https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.public-sg.id
}
resource "aws_security_group_rule" "public-sg-in-ephemeral" {
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.public-sg.id
}
resource "aws_security_group_rule" "public-sg-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.public-sg.id
}

resource "aws_key_pair" "public-key" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

# VPC Resources
resource "aws_vpc" "main" {
  cidr_block           = "10.${var.network-cidr}.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project-name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project-name}-igw"
  }

  depends_on = [aws_vpc.main]
}

resource "aws_eip" "eips" {
  count = length(var.public-subnets)

  tags = {
    Name = "${var.project-name}-eip-${count.index + 1}"
  }
}

resource "aws_subnet" "public-subnets" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(var.public-subnets)
  cidr_block              = element(var.public-subnets, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project-name}-subnet-pb-${count.index + 1}"
  }

  depends_on = [aws_vpc.main]
}

resource "aws_route_table" "public-route-tables" {
  count  = length(var.public-subnets)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project-name}-route-table-pb-${count.index + 1}"
  }
}

resource "aws_route_table_association" "public-route-table-association" {
  count          = length(aws_route_table.public-route-tables.*.id)
  subnet_id      = element(aws_subnet.public-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public-route-tables.*.id, count.index)

  depends_on = [aws_subnet.public-subnets, aws_route_table.public-route-tables]
}

resource "aws_network_acl" "public-network-acl" {
  vpc_id = aws_vpc.main.id
  # https://github.com/terraform-providers/terraform-provider-aws/issues/8974
  subnet_ids = flatten(["${aws_subnet.public-subnets.*.id}"])

  tags = {
    Name = "${var.project-name}-network-acl-pb"
  }

  depends_on = [aws_subnet.public-subnets]
}

resource "aws_network_acl_rule" "in-pb-100" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 100
  protocol       = -1
  egress         = false
  rule_action    = "allow"
  cidr_block     = "10.${var.network-cidr}.0.0/16"
}
resource "aws_network_acl_rule" "in-pb-200" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 200
  protocol       = 6
  egress         = false
  rule_action    = "allow"
  cidr_block     = var.public-cidr-block-in
  from_port      = 80
  to_port        = 80
}
resource "aws_network_acl_rule" "in-pb-210" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 210
  protocol       = 6
  egress         = false
  rule_action    = "allow"
  cidr_block     = var.public-cidr-block-in
  from_port      = 443
  to_port        = 443
}
resource "aws_network_acl_rule" "in-pb-220" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 220
  protocol       = 6
  egress         = false
  rule_action    = "allow"
  cidr_block     = var.source-ip-ssh
  from_port      = 22
  to_port        = 22
}
resource "aws_network_acl_rule" "in-pb-900" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 900
  protocol       = 6
  egress         = false
  rule_action    = "allow"
  cidr_block     = var.public-cidr-block-in
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "out-pb-100" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 100
  protocol       = -1
  egress         = true
  rule_action    = "allow"
  cidr_block     = "10.${var.network-cidr}.0.0/16"
}
resource "aws_network_acl_rule" "out-pb-200" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 200
  protocol       = 6
  egress         = true
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}
resource "aws_network_acl_rule" "out-pb-210" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 210
  protocol       = 6
  egress         = true
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}
resource "aws_network_acl_rule" "out-pb-900" {
  network_acl_id = aws_network_acl.public-network-acl.id
  rule_number    = 900
  protocol       = 6
  egress         = true
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
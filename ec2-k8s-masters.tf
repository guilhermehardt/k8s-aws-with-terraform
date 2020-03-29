## K8s master
resource "aws_instance" "master" {
  count                       = var.k8s-master
  ami                         = data.aws_ami.ubuntu-server.image_id
  instance_type               = var.instance-type
  associate_public_ip_address = true
  subnet_id                   = element(aws_subnet.public-subnets.*.id, count.index)
  key_name                    = aws_key_pair.public-key.key_name
  security_groups             = [aws_security_group.master-sg.id]

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

resource "aws_security_group" "master-sg" {
  name        = "${var.project-name}-master-sg"
  description = "Allow ALB traffic"
  vpc_id      = aws_vpc.main.id
}
resource "aws_security_group_rule" "master-sg-ssh-in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.source-ip-ssh]
  security_group_id = aws_security_group.master-sg.id
}
# all traffic with nodes
resource "aws_security_group_rule" "master-sg-nodes-in" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["10.${var.network-cidr}.0.0/16"]
  security_group_id = aws_security_group.master-sg.id
}
resource "aws_security_group_rule" "master-sg-in-http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = -1
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.master-sg.id
}
resource "aws_security_group_rule" "master-sg-in-https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = -1
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.master-sg.id
}
resource "aws_security_group_rule" "master-sg-in-ephemeral" {
  type              = "ingress"
  from_port         = 1024
  to_port           = 65535
  protocol          = -1
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.master-sg.id
}
resource "aws_security_group_rule" "master-sg-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.master-sg.id
}
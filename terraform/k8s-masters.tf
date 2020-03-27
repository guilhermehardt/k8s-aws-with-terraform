## K8s master
resource "aws_instance" "master" {
  count                       = length(var.k8s-master)
  ami                         = data.aws_ami.ubuntu-server.image_id
  instance_type               = var.instance-type
  associate_public_ip_address = false
  subnet_id                   = element(aws_subnet.public-subnets.*.id, count.index)
  key_name                    = aws_key_pair.public-key.key_name
  security_groups             = [aws_security_group.master-sg.id]

  tags = {
    Name = "${var.project-name}-master-${count.index + 1}"
  }

  depends_on = [aws_vpc.main]
}

resource "aws_security_group" "master-sg" {
  name        = "${var.project-name}-master-sg"
  description = "Allow ALB traffic"
  vpc_id      = aws_vpc.main.id
}
resource "aws_security_group_rule" "master-sg-ssh-in" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion-sg.id
  security_group_id        = aws_security_group.master-sg.id
}
# all traffic with nodes
resource "aws_security_group_rule" "master-sg-nodes-in" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nodes-sg.id
  security_group_id        = aws_security_group.master-sg.id
}
resource "aws_security_group_rule" "master-sg-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.master-sg.id
}
## EC2
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu-server.image_id
  instance_type               = var.instance-type
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public-subnets.1.id
  key_name                    = aws_key_pair.public-key.key_name
  security_groups             = [aws_security_group.bastion-sg.id]

  tags = {
    Name = "${var.project-name}-bastion"
  }

  depends_on = [aws_vpc.main]
}

resource "aws_security_group" "bastion-sg" {
  name        = "${var.project-name}-bastion-sg"
  description = "Allow ALB traffic"
  vpc_id      = aws_vpc.main.id
}
resource "aws_security_group_rule" "bastion-sg-in" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.source-ip-ssh]
  security_group_id = aws_security_group.bastion-sg.id
}
resource "aws_security_group_rule" "bastion-sg-out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.public-cidr-block-in]
  security_group_id = aws_security_group.bastion-sg.id
}
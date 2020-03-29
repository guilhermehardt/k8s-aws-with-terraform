resource "aws_key_pair" "public-key" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}
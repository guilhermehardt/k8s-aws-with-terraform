# Outputs

output "masters-public-ip" {
  value = [aws_instance.master.*.public_ip]
}

output "nodes-public-ip" {
  value = [aws_instance.nodes.*.public_ip]
}
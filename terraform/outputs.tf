output "ec2_public_ip" {
  description = "Public IP of the EC2 instance."
  value       = aws_instance.web.public_ip
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "key_pair_name" {
  description = "Name of the EC2 key pair created by Terraform."
  value       = aws_key_pair.deployer.key_name
}

output "private_key_pem" {
  description = "Private key used for SSH access to the EC2 instance."
  value       = tls_private_key.generated[0].private_key_pem
  sensitive   = true
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_vpc" "default" {
  default = true
}

locals {
  public_key_path = pathexpand("~/.ssh/id_ed25519.pub")
  has_public_key  = fileexists(local.public_key_path)
}

resource "aws_key_pair" "my_local_key" {
  count      = local.has_public_key ? 1 : 0
  key_name   = "my-ssh-key"
  public_key = file(local.public_key_path)
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ec2" {
  name        = "ec2-sg"
  description = "Allow SSH and application traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8081
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name        = "alb-sg"
  description = "Allow HTTP traffic to the application load balancer"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-06468be052a4195a6"
  instance_type          = "t3.small"
  key_name               = length(aws_key_pair.my_local_key) > 0 ? aws_key_pair.my_local_key[0].key_name : null
  vpc_security_group_ids = [aws_security_group.ec2.id]
  tags = {
    Name = "Docker-Ansible-Host"
  }
}

resource "aws_lb" "main" {
  name               = "aws-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids
  timeouts {
    create = "30m"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "docker-targets"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_lb_target_group_attachment" "app1" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "app2" {
  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.web.id
  port             = 8081
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "local_file" "ansible_inventory" {
  content  = <<EOF
[webservers]
${aws_instance.web.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
  filename = "../ansible/inventory.ini"
}

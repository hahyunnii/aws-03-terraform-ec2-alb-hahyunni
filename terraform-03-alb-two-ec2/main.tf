# Reuse the default VPC so the example can focus on load balancing rather than network creation.
data "aws_vpc" "default" {
  default = true
}

# Read all subnets in the default VPC.
data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Read each subnet so Terraform can inspect the Availability Zone for placement.
data "aws_subnet" "default_vpc" {
  for_each = toset(data.aws_subnets.default_vpc.ids)
  id       = each.value
}

# Read the latest Amazon Linux 2023 AMI from the public SSM parameter namespace.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  subnets_by_az = {
    for _, subnet in data.aws_subnet.default_vpc :
    subnet.availability_zone => subnet.id...
  }

  selected_azs = slice(sort(keys(local.subnets_by_az)), 0, 2)
  selected_subnet_ids = [
    for az in local.selected_azs : sort(local.subnets_by_az[az])[0]
  ]

  # Keep stable instance keys so attachments and outputs are easy to read.
  instance_subnet_map = zipmap(["web-a", "web-b"], local.selected_subnet_ids)

  # Create short ALB and target group names that stay within AWS limits.
  alb_name          = substr("${var.name_prefix}-alb", 0, 32)
  target_group_name = substr("${var.name_prefix}-tg", 0, 32)

  common_tags = {
    Course  = "cloud-computing-aws"
    Example = "terraform-03-alb-two-ec2"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow public HTTP traffic to the Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow inbound HTTP from the internet to the ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow the ALB to forward traffic to the EC2 targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "ec2" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "Allow application traffic from the ALB to the EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "Only the ALB security group may reach the application port"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic for package installation and updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-ec2-sg"
  })
}

resource "aws_instance" "web" {
  for_each = local.instance_subnet_map

  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type
  subnet_id     = each.value

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  user_data = templatefile("${path.module}/user-data.sh", {
    app_port    = var.app_port
    name_prefix = var.name_prefix
    server_name = each.key
  })

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}

resource "aws_lb_target_group" "web" {
  name        = local.target_group_name
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  # A basic health check keeps the example concrete and visible in the console.
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
  }

  tags = merge(local.common_tags, {
    Name = local.target_group_name
  })
}

resource "aws_lb_target_group_attachment" "web" {
  # Reuse the aws_instance.web map keys so each instance becomes one target attachment.
  for_each = aws_instance.web

  # Attach each EC2 instance to the target group.
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = each.value.id
  port             = var.app_port
}

resource "aws_lb" "web" {
  name               = local.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.selected_subnet_ids

  tags = merge(local.common_tags, {
    Name = local.alb_name
  })
}

resource "aws_lb_listener" "http" {
  # Attach the listener to the ALB.
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  # Forward listener traffic to the target group.
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

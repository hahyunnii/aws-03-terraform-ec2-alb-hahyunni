# Read the default VPC instead of creating a new network for the first beginner example.
data "aws_vpc" "default" {
  default = true
}

# Read all subnets that belong to the default VPC.
data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Read the latest Amazon Linux 2023 AMI from the public SSM parameter store.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  # TODO(student): Pick the first subnet to keep the first example simple and deterministic.
  # Hint: The data source already returns a list of subnet IDs. Sort it and take one element.
  # selected_subnet_id = sort(data.aws_subnets.default_vpc.ids)[0]

  common_tags = {
    Course  = "cloud-computing-aws"
    Example = "terraform-01-ec2-webserver"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Allow HTTP access to the single EC2 web server"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow inbound HTTP from anywhere for a direct browser test"
    # TODO(student): Allow inbound HTTP from the internet.
    # Hint: Use port 80, protocol tcp, and the public CIDR block 0.0.0.0/0.
    # from_port   = 80
    # to_port     = 80
    # protocol    = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow the instance to reach package repositories and metadata services"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-web-sg"
  })
}

resource "aws_instance" "web" {
  # TODO(student): Use the Amazon Linux 2023 AMI from the SSM parameter.
  # Hint: The AMI value is already available in data.aws_ssm_parameter.al2023_ami.value.
  # ami = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  # TODO(student): Place the instance in the selected subnet local value.
  # Hint: Reuse the local value defined above instead of repeating the subnet lookup logic.
  # subnet_id = local.selected_subnet_id

  # Keep the instance reachable from the internet for the first simple web-server example.
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web.id]

  # templatefile() lets Terraform inject variables into a shell script before EC2 boots.
  # TODO(student): Render the bootstrap shell script with templatefile().
  # Hint: The template path is user-data.sh and the only input variable here is name_prefix.
  # user_data = templatefile("${path.module}/user-data.sh", {
  #   name_prefix = var.name_prefix
  # })

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-web"
  })
}

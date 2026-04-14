# Read the default VPC to avoid unrelated network setup in this example.
data "aws_vpc" "default" {
  default = true
}

# Read all subnet IDs that belong to the default VPC.
data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Read each subnet individually so Terraform can access attributes such as the Availability Zone.
data "aws_subnet" "default_vpc" {
  for_each = toset(data.aws_subnets.default_vpc.ids)
  id       = each.value
}

# Read the latest Amazon Linux 2023 AMI from SSM.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  # TODO(student): Build a map like { "us-east-1a" = ["subnet-123"], "us-east-1b" = ["subnet-456"] }.
  # Hint: Iterate over data.aws_subnet.default_vpc and group by availability_zone using the ... syntax.
  # subnets_by_az = {
  #   for _, subnet in data.aws_subnet.default_vpc :
  #   subnet.availability_zone => subnet.id...
  # }

  # TODO(student): Select the first two Availability Zones in sorted order.
  # Hint: Use sort(keys(...)) and then slice the first two items.
  # selected_azs = slice(sort(keys(local.subnets_by_az)), 0, 2)

  # TODO(student): Pick one subnet from each selected Availability Zone.
  # Hint: A for-expression can transform selected_azs into a list of subnet IDs.
  # selected_subnet_ids = [
  #   for az in local.selected_azs : sort(local.subnets_by_az[az])[0]
  # ]

  # TODO(student): Map the logical instance names to the selected subnet IDs.
  # Hint: zipmap() is the intended function here.
  # instance_subnet_map = zipmap(["web-a", "web-b"], local.selected_subnet_ids)

  common_tags = {
    Course  = "cloud-computing-aws"
    Example = "terraform-02-ec2-two-subnets"
  }
}

resource "aws_security_group" "web" {
  name        = "${var.name_prefix}-web-sg"
  description = "Allow direct HTTP access to both EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow inbound HTTP from anywhere for easy per-instance testing"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic for package installation and updates"
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
  # for_each creates one instance per map entry and gives each instance a stable logical key.
  # TODO(student): Iterate over the instance-to-subnet map.
  # Hint: The map is already prepared in local.instance_subnet_map.
  # for_each = local.instance_subnet_map

  ami           = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  # TODO(student): Place each instance in the subnet from the map value.
  # Hint: With for_each on a map, each.value is the subnet ID and each.key is the server name.
  # subnet_id = each.value

  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web.id]

  # TODO(student): Pass both name_prefix and server_name into the user-data template.
  # Hint: server_name should come from the for_each key.
  # user_data = templatefile("${path.module}/user-data.sh", {
  #   name_prefix = var.name_prefix
  #   server_name = each.key
  # })

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}

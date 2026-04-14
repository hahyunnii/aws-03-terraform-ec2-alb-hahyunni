# Toy Example 01: EC2 Creation and Web Server Setup

This folder is a student template, not a fully completed solution.
Some key Terraform lines are intentionally removed and replaced with `TODO(student)` comments.

This example creates one EC2 instance in the default VPC, installs Nginx with `user_data`, and exposes the web server directly on port `80`.

## Learning Focus

- How to declare an AWS provider and basic input variables
- How to read existing AWS infrastructure with `data` sources
- How to create one EC2 instance and one security group
- How to use `templatefile()` to pass values into a startup script
- How to return useful values with `output`

## Included Files

- `versions.tf`: Terraform and provider requirements
- `variables.tf`: input variables
- `main.tf`: data sources, security group, EC2 instance
- `outputs.tf`: public IP, DNS name, and subnet ID
- `user-data.sh`: installs and starts Nginx
- `terraform.tfvars.example`: example variable values
- `commands.md`: command examples with English comments

## Lab Outcome

The lab creates:

- one EC2 instance
- one security group that allows HTTP from the internet
- one simple Nginx page generated during boot

Traffic path:

- client -> EC2 port `80`

## Quick Start

```bash
export project_root="/path/to/your/project_root"
cd "$project_root/eng/toy-examples/terraform/terraform_example/terraform-01-ec2-webserver"

# Load AWS Academy temporary credentials into environment variables.
export AWS_ACCESS_KEY_ID="<your-access-key-id>"
export AWS_SECRET_ACCESS_KEY="<your-secret-access-key>"
export AWS_SESSION_TOKEN="<your-session-token>"

cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt

# Complete the TODO(student) sections before validation.
terraform validate
terraform plan
terraform apply
terraform output
curl "http://$(terraform output -raw instance_public_ip)"
terraform destroy
```

## Notes

- This example uses the first default subnet in the default VPC.
- The instance is given a public IP so the web server can be tested directly from the browser or `curl`.
- Keep sensitive values such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` in environment variables only.
- Use `terraform.tfvars` only for non-sensitive inputs such as `aws_region`, `name_prefix`, and `instance_type`.

## Student Tasks

- Complete the local value that selects one subnet from the default VPC.
- Complete the HTTP ingress rule in the web security group.
- Complete the EC2 instance fields for AMI, subnet placement, and `user_data`.

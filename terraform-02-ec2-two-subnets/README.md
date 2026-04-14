# Toy Example 02: Two EC2 Instances in Different Subnets

This folder is a student template, not a fully completed solution.
The base structure is preserved, but several multi-subnet and repetition lines are intentionally removed.

This example creates two EC2 instances and places them in two different default subnets.
It extends Example 01 by introducing repetition with `for_each` and subnet selection logic with Terraform expressions.

## Learning Focus

- How to inspect multiple subnets with `data` sources
- How to group subnets by Availability Zone
- How to create multiple EC2 instances with `for_each`
- How to map instance names to subnet IDs with `zipmap`
- How to inspect plans and state with additional Terraform commands

## Included Files

- `versions.tf`: Terraform and provider requirements
- `variables.tf`: input variables
- `main.tf`: subnet discovery, security group, and two EC2 instances
- `outputs.tf`: instance IDs, public IPs, and selected subnets
- `user-data.sh`: installs and starts Nginx on each instance
- `terraform.tfvars.example`: example variable values
- `commands.md`: command examples with English comments

## Lab Outcome

The lab creates:

- two EC2 instances
- one shared security group for HTTP
- one simple Nginx page on each instance
- one placement map that spreads the instances across two subnets

Traffic path:

- client -> EC2 port `80`

## Quick Start

```bash
export project_root="/path/to/your/project_root"
cd "$project_root/eng/toy-examples/terraform/terraform_example/terraform-02-ec2-two-subnets"

# Load AWS Academy temporary credentials into environment variables.
export AWS_ACCESS_KEY_ID="<your-access-key-id>"
export AWS_SECRET_ACCESS_KEY="<your-secret-access-key>"
export AWS_SESSION_TOKEN="<your-session-token>"

cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt

# Complete the TODO(student) sections before validation.
terraform validate
terraform plan -out plan.out
terraform show plan.out
terraform apply plan.out
terraform output
terraform state list
terraform destroy
```

## Notes

- This example expects the AWS region to have at least two default subnets.
- The two instance names are fixed as `web-a` and `web-b` to make the `for_each` map easy to read.
- Keep sensitive values such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_SESSION_TOKEN` in environment variables only.
- Use `terraform.tfvars` only for non-sensitive inputs such as `aws_region`, `name_prefix`, and `instance_type`.

## Student Tasks

- Complete the `locals` block that groups subnets by Availability Zone.
- Complete the logic that chooses two subnet IDs and maps them to `web-a` and `web-b`.
- Complete the `for_each`-based EC2 resource and its `user_data` arguments.

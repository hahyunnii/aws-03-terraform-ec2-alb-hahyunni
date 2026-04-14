# Commands Log Template

## Preflight

```bash
# Confirm that AWS Academy temporary credentials are present as environment variables.
test -n "$AWS_ACCESS_KEY_ID" && echo "AWS_ACCESS_KEY_ID is set"
test -n "$AWS_SECRET_ACCESS_KEY" && echo "AWS_SECRET_ACCESS_KEY is set"
test -n "$AWS_SESSION_TOKEN" && echo "AWS_SESSION_TOKEN is set"

# Confirm that AWS credentials are active in the current shell.
aws sts get-caller-identity

# Confirm the default AWS region that Terraform will use.
aws configure get region

# Confirm that Terraform is installed.
terraform version
```

Key output:

Interpretation:

## Init and Format

```bash
# Download the AWS provider plugin into the local .terraform directory.
terraform init

# Rewrite Terraform files into canonical formatting.
terraform fmt
```

Key output:

Interpretation:

## Validate and Plan

```bash
# Check Terraform syntax and provider/resource references.
terraform validate

# Preview what Terraform will create before making changes.
terraform plan
```

Key output:

Interpretation:

## Apply and Verify

```bash
# Create the EC2 instance and supporting resources.
terraform apply

# Read all defined outputs after apply finishes.
terraform output

# Read only the public IP in raw form so it can be used in shell commands.
terraform output -raw instance_public_ip

# Send one HTTP request directly to the instance.
curl "http://$(terraform output -raw instance_public_ip)"
```

Key output:

Interpretation:

## Cleanup

```bash
# Delete all resources created by this example.
terraform destroy
```

Key output:

Interpretation:

## Credential Handling Note

```text
Store AWS Academy temporary credentials in environment variables only.
Do not put AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or AWS_SESSION_TOKEN into terraform.tfvars.
```

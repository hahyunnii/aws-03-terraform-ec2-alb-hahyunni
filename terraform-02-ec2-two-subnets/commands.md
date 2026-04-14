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
```

Key output:

Interpretation:

## Init and Validation

```bash
# Initialize the working directory and download the AWS provider.
terraform init

# Format Terraform files consistently.
terraform fmt

# Validate configuration syntax before planning.
terraform validate
```

Key output:

Interpretation:

## Saved Plan

```bash
# Save the execution plan into a file so the exact reviewed plan can be applied later.
terraform plan -out plan.out

# Print the saved plan file in human-readable form.
terraform show plan.out
```

Key output:

Interpretation:

## Apply and Outputs

```bash
# Apply the exact saved plan instead of recalculating a new plan.
terraform apply plan.out

# Read all outputs, including the selected subnet IDs and instance IPs.
terraform output
```

Key output:

Interpretation:

## State Inspection

```bash
# List every object Terraform is currently tracking in the state file.
terraform state list

# Open the Terraform expression console for ad hoc inspection.
terraform console
```

Useful console expressions:

```text
local.instance_subnet_map
keys(aws_instance.web)
values(aws_instance.web)[*].public_ip
```

Key output:

Interpretation:

## Cleanup

```bash
# Destroy all resources from this example after verification is complete.
terraform destroy
```

Key output:

Interpretation:

## Credential Handling Note

```text
Store AWS Academy temporary credentials in environment variables only.
Do not put AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or AWS_SESSION_TOKEN into terraform.tfvars.
```

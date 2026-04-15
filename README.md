[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/brdYypEt)
# Terraform Student Templates

This folder contains student-facing Terraform templates based on the three toy examples.

## Purpose

- Keep the overall file structure and comments visible
- Remove a few key implementation lines so students must complete them
- Let students practice Terraform block reading, editing, validation, and troubleshooting

## Template Progression

1. `terraform-01-ec2-webserver`
   - Students complete the single-instance baseline

2. `terraform-02-ec2-two-subnets`
   - Students extend the baseline with multi-subnet placement and `for_each`

3. `terraform-03-alb-two-ec2`
   - Students extend the second example with ALB resources

## Important Note

- These folders are intentionally incomplete templates.
- `terraform validate` or `terraform plan` may fail until students complete the `TODO(student)` sections.
- Most `TODO(student)` blocks also include a short hint comment to guide the next step without giving the full answer away.

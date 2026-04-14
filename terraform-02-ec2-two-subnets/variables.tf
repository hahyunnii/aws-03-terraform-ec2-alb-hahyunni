variable "aws_region" {
  description = "AWS region for this example"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Short prefix used in AWS resource names"
  type        = string
  default     = "ccaws-tf02"
}

variable "instance_type" {
  description = "EC2 instance type for both web servers"
  type        = string
  default     = "t3.micro"
}

variable "aws_region" {
  description = "AWS region for this example"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Short prefix used in AWS resource names"
  type        = string
  default     = "ccaws-tf01"
}

variable "instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t3.micro"
}

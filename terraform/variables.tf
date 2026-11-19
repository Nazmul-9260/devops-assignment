variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "ami_id" {
  type        = string
  description = "Ubuntu 22.04 LTS AMI ID"
  default     = "ami-0c7217cdde317cfec" # Example AMI
}

variable "ssh_public_key" {
  description = "Public SSH key used to connect to the EC2 instance."
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region for resources."
  type        = string
  default     = "eu-west-1"
}

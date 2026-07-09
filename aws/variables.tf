variable "aws_region" {
  description = "AWS Region"
  type	      = string
  default     = "us-east-1"
}

variable "instance_count" {
  description = "EC2 Instance Count"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 Instance Type"
  type        = string
  default     = "t3.small"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token"
  type        = string
  default     = null
  sensitive   = true
}

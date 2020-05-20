variable "aws_region" {
  type = string
}

variable "sns_topic" {
  type = string
}

variable "time_limit" {
  type = number
}

variable "asg_name" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "lambda_timeout" {
  type = number
}

variable "volume_size" {
  type = map(string)
}

variable "volume_type" {
  type = map(string)
}

variable "volume_iops" {
  type = map(string)
}

variable "mount_point" {
  type = map(string)
}

variable "tag_name" {
  type = string
}

variable "tag_value" {
  type = map(string)
}

variable "extra_tags" {
  type = map(string)
}

variable "encrypted" {
  type = map(string)
}

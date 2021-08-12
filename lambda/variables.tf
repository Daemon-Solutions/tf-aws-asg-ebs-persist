variable "aws_region" {
}

variable "sns_topic" {
}

variable "time_limit" {
  type = string
}

variable "asg_name" {
}

variable "runtime" {
  type = string
}

variable "lambda_role_arn" {
}

variable "lambda_timeout" {
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

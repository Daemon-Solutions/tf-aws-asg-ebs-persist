variable "env" {}

variable "sns_topic" {}

variable "time_limit" {
  type = "string"
}

variable "stack_name" {}

variable "lambda_role_arn" {}

variable "lambda_version" {}

variable "lambda_timeout" {}

variable "volume_size" {
  type = "map"
}

variable "volume_type" {
  type = "map"
}

variable "volume_iops" {
  type = "map"
}

variable "mount_point" {
  type = "map"
}

variable "tag_name" {
  type = "string"
}

variable "tag_value" {
  type = "map"
}

variable "encrypted" {
  type = "map"
}

variable "client_name" {}

variable "asg_name" {
  type = string
}

variable "function_arn" {
  type = string
}

variable "function_name" {
  type = string
}

variable "suffix" {
  type    = string
  default = "ebs-persist"
}

variable "aws_region" {
  type        = string
  description = "AWS region to host your network"
}

variable "tag_name" {
  type        = string
  description = "Tag Name to identify EBS volume"
  default     = "tf-aws-asg-ebs-persist"
}

variable "time_limit" {
  type        = number
  description = "The max age of a snapshot to use it"
  default     = 300
}

variable "lambda_timeout" {
  type    = number
  default = 300
}

variable "asg_name" {
  type = string
}

#Below the EBS configuration. Important! Always keep the same order for each section(example: sdf param and after sdf param)!
variable "mount_point" {
  type        = map(string)
  description = "EBS mount point for each disk"

  default = {
    sdp = "/dev/sdp"
  }
}

variable "block_type" {
  type        = map(string)
  description = "EBS type for each disk"

  default = {
    #Type of storage. Valid values are 'standard'|'io1'|'gp2'|'sc1'|'st1'
    sdp = "gp2"
  }
}

variable "block_size" {
  type        = map(string)
  description = "EBS size for each disk"

  default = {
    #The size of the new EBS volume in GB.
    sdp = "70"
  }
}

variable "block_iops" {
  type        = map(string)
  description = "EBS iops for each disk"

  default = {
    #Iops are only available with Provisioned IOPS(io1). Set the number of Iops/second with a maximum of 30 IOPS/GB.
    #The 0 value indicate that IOPS are not customizable for this EBS type.
    sdp = "0"
  }
}

variable "tag_value" {
  type        = map(string)
  description = "Tag Value to identify EBS volume"

  default = {
    #tag key:value to identify members of the stack.If your instances are already running with dtas disks already attached.
    #Think to tag the EBS volumes with these.
    sdp = "true"
  }
}

variable "extra_tags" {
  type        = map(string)
  description = "Additional EBS tags"

  default = {}
}

variable "encrypted" {
  type        = map(string)
  description = "Enable encryption for EBS volume"

  default = {
    sdp = "False"
  }
}

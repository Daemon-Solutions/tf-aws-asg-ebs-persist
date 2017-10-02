variable "aws_region" {
  description = "AWS region to host your network"
  type        = "string"
}

variable "envname" {
  description = "Environment name"
  type        = "string"
}

variable "tag_name" {
  description = "Tag Name to identify EBS volume"
  default     = "tf-aws-asg-ebs-persist"
}

variable "time_limit" {
  description = "The max age of a snapshot to use it"
  default     = 300
}

variable "lambda_timeout" {
  default = 300
}

variable "asg_name" {
  type = "string"
}

#Below the EBS configuration. Important! Always keep the same order for each section(example: sdf param and after sdf param)!
variable "mount_point" {
  description = "EBS mount point for each disk"

  default {
    sdp = "/dev/sdp"
  }
}

variable "block_type" {
  description = "EBS type for each disk"

  default {
    #Type of storage. Valid values are 'standard'|'io1'|'gp2'|'sc1'|'st1'
    sdp = "gp2"
  }
}

variable "block_size" {
  description = "EBS size for each disk"

  default {
    #The size of the new EBS volume in GB.
    sdp = "70"
  }
}

variable "block_iops" {
  description = "EBS iops for each disk"

  default {
    #Iops are only available with Provisioned IOPS(io1). Set the number of Iops/second with a maximum of 30 IOPS/GB.
    #The 0 value indicate that IOPS are not customizable for this EBS type.
    sdp = "0"
  }
}

variable "tag_value" {
  description = "Tag Value to identify EBS volume"

  default {
    #tag key:value to identify members of the stack.If your instances are already running with dtas disks already attached. 
    #Think to tag the EBS volumes with these.
    sdp = "true"
  }
}

variable "encrypted" {
  description = "Enable encryption for EBS volume"
  type        = "map"

  default {
    sdp = "False"
  }
}

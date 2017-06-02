# Descripton

Module to provide EBS volume persistance to ASG based instances.
This is based on the morea module.

```
- This can create multiple EBS volume attatchments
- If the volumes do not exist, it will create them. (E.g. on ASG creation)
- Volume reszing does work for existing volumes. Snapshot the existing volumes beforehand (as we are limited to 5  mins for a lambda operation)
- An s3 bucket to store the lambda function is created. 
- To deal with the ASG not sending an notificaiton to the SNS topic on first creation, there is a local-exec command run by terraform to send a TEST_NOTIFICTION, which triggers the lamba function to audit the ASG members and attatch volumes.

```

Top level Modifications from morea module:
```
Support for (Requires) Terraform 0.7
Will create volumes for a newly created ASG
```

Example reference (from a kafka example):

```
module "kafka_ebs" {
  source = "../localmodules/tf-aws-asg-ebs-persist" 
  aws_region = "eu-west-1"
  
  stack_instances {
    stack_name = "${module.kafka5.asg_name}"
    autoscaling_name = "${module.kafka5.asg_name}"	#Set this to the ASG Name
    lambda_timeout = "300"				#Max 5 minute timeout from  Lambda
    lambda_version = "1.0.0"				#Increment this if change any settings in module
  }

  general {				
    env = "${var.envname}"		
    client_name = "${var.envname}"
    tag_value = "kafka"
    tag_name = "ebsattatch"
    time_limit = "300"
  }
  mount_point {				# Mount point on EC2 instance 
    "0" = "/dev/sdf" 
    "1" = "/dev/sdg"
  }
  block_iops  {				#This is 0 for gp2 type disks. Set to #val if using piops
    "0" = "0"
    "1" = "0"
  }
  block_size {				#Size in GB of disks
    "0" = "11"
    "1" = "12"
  }
  block_type {				#EBS voltype
    "0" = "gp2"
    "1" = "gp2"
  }
  tag_value {				#tags to differentiate different types of disks.
    "0" = "kafka_data"			
    "1" = "kafka_vol"
  }  
  
  encrypted {				# encrypts EBS, "True" or "true" or "1" will enable encryption, anything else will be evaluated to False
    "0" = "True"
    "1" = "False"
    "2" = "True"
  }  
}
```

See below for mounting / performing resizing of increased size volume disks



---------------
Old Docs:

# Description

This terraform template creates an EBS affinity for instances which are members of a same Autoscaling Group. The goal is to attach a datas disk on a new instance related to specific conditions.
It provides also a way to easily resize(only increase) or change the type of an EBS volume.

# Key Features:

* Create a Lambda function and an SNS Topic. Set the new SNS topic as notification target of the Autoscaling Group. Add also the "invokation" feature from the SNS topic to the Lambda.
* Attach the "free volume(s)" of a terminated instance to the new one which has been launched in replacement.
* A "free volume" is an EBS in the same Availability Zone than the instance and with the tag name and value define in the variable.tf
* Give the possibility to easily resize an EBS or to change is type. You just need to update this terraform and replace the instance inside the Autoscaling Group(The new instance will have the older EBS disk resized or with the new type(ex: io1/gp2/...).
* You can define one or more EBS disk to attach to the new instance.
* If the attach process has failed, you just need to handle that in your startup script to let the instance "unhealthy". The instance will be replaced by the Autoscaling Group and the next one will relaunched/finished the attachment proccess. 
* When a resize or change type action is performed, the process tryed to use a recent snapshot(delta time is configurable) to create a new volume. If there is no snapshot available, a new one is created and the new volume will use it. 


The only missing part, is the bootstrap script(userdata or in the ghost lifecycle pre bootstrap) to auto mount or/and resize the disk.
Below an example of possible script:

    #!bin/bash
    
    set -x
    
    MOUNT_POINT=/dev/xvdp
    MOUNT_PATH=/mnt/test
    FILE_SYSTEM_TYPE=ext4
    
    if (( "$(blkid |grep ${MOUNT_POINT} |wc -l)" == "0" ))
    then
    	mkfs.${FILE_SYSTEM_TYPE} ${MOUNT_POINT}
    fi
    
    if [ ! -d "$MOUNT_PATH" ]
    then
    	mkdir ${MOUNT_PATH}
    fi
    
    mount -t ${FILE_SYSTEM_TYPE} ${MOUNT_POINT} ${MOUNT_PATH}
    
    resize2fs ${MOUNT_POINT}

This process is based on a Lambda function which hold the entire logic. In the case of the attachment or resize process failed, it would have no impact while your health check failed(think to do not start your application process until the disk was mounted). If there is a problem during this step, the autoscaling will terminate the instance and will create a new one and relaunch the attachment/resize process.

If you need to update the lambda conf(resize/add/change type of an or multiple EBS) you just need to update your variables.tf and think to change the Lambda version number inside this variable.tf

# Requirements
* Your Autoscaling Group must already exists

# Usage
You can use this module as a "standalone" module. To do that just configure rename the main and variables files with the name "standalone" and execute it as usual. 
Or you can use this module as submodule to call it from another main.tf. To do just call this module as a submodule in your main.tf with the variables values.

# Quick Usage: Sample main.tf that use autoscaling and other modules

    provider "aws" {
      region = "${var.aws_region}"
    }
    
    module "as_notification" {
      source           = "as_notification"
      sns_topic_arn    = "${module.sns.sns_topic_arn}"
      autoscaling_name = "${var.stack_instances.autoscaling_name}"
    }
    
    module "iam" {
      source     = "iam"
      env        = "${var.general.env}"
      stack_name = "${var.stack_instances.stack_name}"
      account_id = "${var.general.account_id}"
      aws_region = "${var.aws_region}"
      tag_name   = "${var.stack_instances.tag_name}"
      tag_value  = "${var.stack_instances.tag_value}"
    }
    
    module "s3" {
      source      = "s3"
      env         = "${var.general.env}"
      client_name = "${var.general.client_name}"
      aws_region  = "${var.aws_region}"
    }
    
    module "sns" {
      source     = "sns"
      env        = "${var.general.env}"
      stack_name = "${var.stack_instances.stack_name}"
    }
    
    module "lambda" {
      source          = "lambda"
      client_name     = "${var.general.client_name}"
      env             = "${var.general.env}"
      sns_topic       = "${module.sns.sns_topic_arn}"
      stack_name      = "${var.stack_instances.stack_name}"
      lambda_role_arn = "${module.iam.iam_role_lambda_arn}"
      lambda_version  = "${var.stack_instances.lambda_version}"
      lambda_timeout  = "${var.stack_instances.lambda_timeout}"
      volume_size     = "${values("block_size")}"
      volume_type     = "${values("block_type")}"
      volume_iops     = "${values("block_iops")}"
      mount_point     = "${values("mount_point")}"
      tag_name        = "${values("tag_name")}"
      tag_value       = "${values("tag_value")}"
      tag_value       = "${values("tag_value")}"
      time_limit      = "${values("time_limit")}"
    }
    
## Sample variable.tf

This example managed 2 EBS disks for each instance which is a member of the autoscaling group.

    variable "aws_region" {
      description = "AWS region to host your network"
    }
    
    #General Informations
    variable "general" {
      description = "General variables"

      default {
        env         = "test"
        client_name = "mattboret"
        account_id  = "77853888888"
      }
    }
    #Stack general informations
    variable "stack_instances" {
      description = "Autoscaling Stack Informations"
    
      default {
        stack_name = "cluster-es"
      
        #Don't forget to update the version to update the Lambda code in AWS.
        lambda_version = "v1.0.2"
        lambda_timeout = "60"
    
        autoscaling_name = "as-elasticsearch"
      }
    }

    #Below the EBS configuration. Important! Always keep the same order for each section(example: sdf param and after sdf param)!
    variable "mount_point" {
      description = "EBS mount point for each disk"
    
      default {
        sdp = "/dev/sdp"
        sdf = "/dev/sdf"
      }
    }
    
    variable "block_type" {
      description = "EBS type for each disk"
    
      default {
        #Type of storage. Valid values are 'standard'|'io1'|'gp2'|'sc1'|'st1'
        sdp = "io1"
        sdf = "standard"
      }
    }
        
    variable "block_size" {
      description = "EBS size for each disk"
    
      default {
        #The size of the new EBS volume in GB.
        sdp = "50"
        sdf = "30"
      }
    }
     
    variable "block_iops" {
      description = "EBS iops for each disk"
    
      default {
        #Iops are only available with Provisioned IOPS(io1). Set the number of Iops/second with a maximum of 30 IOPS/GB.
        #The 0 value indicate that IOPS are not customizable for this EBS type.
        sdp = "100"
        sdf = "0"
      }
    }
     
    variable "tag_name" {
      description = "Tag Name to identify EBS volume"

      default {
        #tag key:value to identify members of the stack.If your instances are already running with datas disks already attached. 
        #Think to tag the EBS volumes with these.
        sdp = "es_cluster_datas"
        sdf = "es_cluster_logs"
      }
    }
     
    variable "tag_value" {
      description = "Tag Value to identify EBS volume"
     
      default {
        #tag key:value to identify members of the stack.If your instances are already running with dtas disks already attached. 
        #Think to tag the EBS volumes with these.
        sdp = "true"
        sdf = "true"
      }
    }
     
    variable "time_limit" {
      description = "The max age of a snapshot to use it"
     
      default {
        #Time limit define the max delta time, in minutes, of the snapshot creation. If the creation time is less than this limit,
        #this snpashot will be used to create a new volume when the disk size has been increased. 
        sdp = "30"
        sdf = "20"
      }
    }
    

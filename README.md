# tf-aws-asg-ebs-persist

Module to provide EBS volume persistence for ASG based instances.

## Terraform version compatibility
| Module version | Terraform version |
|---|---|
| 3.x.x | 0.12.x |
| 2.x.x | 0.11.x |

## Description

This module creates an EBS affinity for instances which are members of the same Autoscaling Group. The goal is to attach an EBS volume to a new instance, reusing or creating new volumes as necessary. It also provides a way to resize (increase only) or change the type of EBS volume.

This is based on a module by Morea.

## Features

* This can create multiple EBS volume attachments
* If the volumes do not exist, it will create them
* Volume resizing does work for existing volumes
  * Hint: manually snapshot the existing volumes beforehand because we are limited to 5 mins for a lambda operation
* Will create volumes for a newly created ASG

## Example

```
module "kafka_ebs" {
  source = "../localmodules/tf-aws-asg-ebs-persist"

  aws_region = "eu-west-1"
  asg_name   = "${module.kafka5.asg_name}"

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
  extra_tags {				# Additional tags to EBS. Must be prefixed with the volume key
    "0.Name"   = "Kafka Volume"
    "0.Backup" = "Backup_Retention"
  }
  encrypted {				# encrypts EBS, "True" or "true" or "1" will enable encryption, anything else will be evaluated to False
    "0" = "True"
    "1" = "False"
    "2" = "True"
  }
}
```

# Further details:

* Attaches the "free volume(s)" of a terminated instance to the new one which has been launched in replacement.
* A "free volume" is an EBS in the same Availability Zone as the instance and with the tag name and value defined in the variables given to this module.
* Gives the possibility to easily resize an EBS or to change its type. You just need to update this terraform and replace the instance inside the Autoscaling Group. The new instance will have the older EBS disk resized or with the new type.
* You can define one or more EBS disks to attach to a new instance.
* If the attach process has failed, you need to handle that in your startup script to make the instance "unhealthy". The instance will be replaced by the Autoscaling Group and the next one will relaunched and hopefully finish the attachment process.
* When a resize or change type action is performed, the process tries to use a recent snapshot (delta time is configurable) to create a new volume. If there is no snapshot available, a new one is created and the new volume will use it.
* To deal with the ASG not sending a notification to the SNS topic on first creation, there is a local-exec command run by terraform to send a TEST_NOTIFICATION, which triggers the lamba function to audit the ASG members and attatch volumes.

The only missing part, is the bootstrap script (userdata or boot service) to auto mount or/and resize the disk.
Below is an example script:

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

In the case of an attachment or resize failure during instance startup, it should have no impact as long as the instance health check fails. Ensure that any applications on the system are not started before the disk is successfully mounted. Alternatively, use lifecycle hooks to only put the instance in service after successfully mounting the disk. If there is a problem during this step, the autoscaling group will terminate the unhealthy/pending instance and will create a new one that can try again.

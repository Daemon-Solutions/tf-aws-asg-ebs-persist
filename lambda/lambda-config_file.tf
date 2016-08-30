resource "null_resource" "clean_lambda_conf" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }
  provisioner "local-exec" {
    command = "rm /tmp/lambda_as_ebs.conf |true"
  }
}

resource "null_resource" "build_lambda_conf" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }
  depends_on = ["null_resource.clean_lambda_conf"]
  count = "2"

  provisioner "local-exec" {  
    command = "echo  \"[${lookup(var.mount_point, count.index)}]]\ntime_limit=${var.time_limit}\nvolume_size=${lookup(var.volume_size, count.index)}\nvolume_type=${lookup(var.volume_type, count.index)}\nvolume_iops=${lookup(var.volume_iops, count.index)}\nmount_point=${lookup(var.mount_point, count.index)}\ntag_name=${var.tag_name}\ntag_value=${lookup(var.tag_value, count.index)}\n  \" >> /tmp/lambda_as_ebs.conf"
  }
}

resource "null_resource" "build_lambda_zip" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }
  depends_on = ["null_resource.clean_lambda_conf", "null_resource.build_lambda_conf"]

  provisioner "local-exec" {
    command = "cp -f ${path.module}/scripts/main.py /tmp/; cd /tmp/; zip -r lambda_as_ebs-${var.env}-${var.lambda_version}-management.zip main.py lambda_as_ebs.conf"
  }
}

resource "null_resource" "notifySNSTopic" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }
  depends_on = ["aws_sns_topic_subscription.lambda_subscription"]
  provisioner "local-exec" {
    #Sends the  SNS Topic a notificiation that the ASG has been created. Works around dependency problem of SNS ASG notificiation cycle.
    command = "aws sns publish --topic-arn ${var.sns_topic} --message \"{ \\\"Event\\\": \\\"autoscaling:TEST_NOTIFICATION\\\", \\\"AutoScalingGroupName\\\": \\\"${var.stack_name}\\\" }\""
  }
}

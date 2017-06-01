resource "null_resource" "clean_lambda_conf" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  provisioner "local-exec" {
    command = "rm ${path.module}/scripts/lambda_as_ebs.conf |true"
  }
}

resource "null_resource" "build_lambda_conf" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  depends_on = ["null_resource.clean_lambda_conf"]
  count      = "${length(keys(var.mount_point))}"

  provisioner "local-exec" {
    command = <<EOFTERRAFORM
cat << EOFBASH  > /tmp/lambda_as_ebs.conf
[${lookup(var.mount_point, count.index)}]
time_limit=${var.time_limit}
volume_size=${lookup(var.volume_size, count.index)}
volume_type=${lookup(var.volume_type, count.index)}
volume_iops=${lookup(var.volume_iops, count.index)}
mount_point=${lookup(var.mount_point, count.index)}
tag_name=${var.tag_name}
tag_value=${lookup(var.tag_value, count.index)}
encrypted=${lookup(var.encrypted, count.index)}

EOFBASH
EOFTERRAFORM
  }
}

## create lambda package
data "archive_file" "lambda_package" {
  depends_on = [null_resource.build_lambda_conf]
  type        = "zip"
  source_dir  = "${path.module}/scripts"
  output_path = "/tmp/lambda_as_ebs-${var.env}-${var.lambda_version}-management.zip"
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

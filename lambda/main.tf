# Null resources creating configs and zips
resource "null_resource" "clean_local_lambda_confs" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  provisioner "local-exec" {
    command = "rm /tmp/${var.lambda_client}/lambda_as_ebs.conf||true; rm /tmp/${var.lambda_client}/lambda_as_ebs-${var.env}-${var.lambda_version}-${var.lambda_client}-management.zip||true"
  }
}

resource "null_resource" "build_lambda_conf" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  depends_on = ["null_resource.clean_local_lambda_confs"]
  count      = "${length(keys(var.mount_point))}"

  provisioner "local-exec" {
    command = "mkdir /tmp/${var.lambda_client}; echo  \"[${lookup(var.mount_point, count.index)}]]\ntime_limit=${var.time_limit}\nvolume_size=${lookup(var.volume_size, count.index)}\nvolume_type=${lookup(var.volume_type, count.index)}\nvolume_iops=${lookup(var.volume_iops, count.index)}\nmount_point=${lookup(var.mount_point, count.index)}\ntag_name=${var.tag_name}\ntag_value=${lookup(var.tag_value, count.index)}\n  \" >> /tmp/${var.lambda_client}/lambda_as_ebs.conf"
  }
}

resource "null_resource" "build_lambda_zip" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  depends_on = ["null_resource.build_lambda_conf"]

  provisioner "local-exec" {
    command = "cp -f ${path.module}/scripts/main.py /tmp/${var.lambda_client}/; cd /tmp/${var.lambda_client}/; zip -r lambda_as_ebs-${var.env}-${var.lambda_version}-${var.lambda_client}-management.zip main.py lambda_as_ebs.conf"
  }
}

resource "null_resource" "notifySNSTopic" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  depends_on = ["aws_sns_topic_subscription.lambda_subscription"]

  provisioner "local-exec" {
    /* Sends the  SNS Topic a notificiation that the ASG has been created. Works
           around dependency problem of SNS ASG notificiation cycle. */
    command = "aws sns publish --topic-arn ${var.sns_topic} --message \"{ \\\"Event\\\": \\\"autoscaling:TEST_NOTIFICATION\\\", \\\"AutoScalingGroupName\\\": \\\"${var.stack_name}\\\" }\""
  }
}

# Main stuff
resource "aws_lambda_function" "new_lambda" {
  depends_on = ["null_resource.build_lambda_zip"]

  filename         = "/tmp/${var.lambda_client}/lambda_as_ebs-${var.env}-${var.lambda_version}-${var.lambda_client}-management.zip"
  function_name    = "lambda_as_es_${var.env}_${var.stack_name}"
  role             = "${var.lambda_role_arn}"
  handler          = "main.lambda_handler"
  description      = "Lambda function to manage the EBS affinity for the stack ${var.stack_name} in ${var.env} env"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn              = "${var.sns_topic}"
  protocol               = "lambda"
  endpoint_auto_confirms = "true"
  endpoint               = "${aws_lambda_function.new_lambda.arn}"
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.new_lambda.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${var.sns_topic}"
}

output "lambda_function_id" {
  value = "${aws_lambda_function.new_lambda.arn}"
}

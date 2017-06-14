# get current account id
data "aws_caller_identity" "current" {}

data "external" "lambda_files" {
  program = ["python", "${path.module}/scripts/data.py"]

  query = {
    module_path    = "${path.module}"
    stack_name     = "${var.stack_name}"
    lambda_version = "${var.lambda_version}"

    # dicts
    mount_point = "${jsonencode(var.mount_point)}"
    volume_size = "${jsonencode(var.volume_size)}"
    volume_type = "${jsonencode(var.volume_type)}"
    volume_iops = "${jsonencode(var.volume_iops)}"
    tag_value   = "${jsonencode(var.tag_value)}"
    encrypted   = "${jsonencode(var.encrypted)}"

    #string
    tag_name   = "${var.tag_name}"
    time_limit = "${var.time_limit}"
  }
}

## create lambda package
data "archive_file" "lambda_package" {
  type        = "zip"
  source_dir  = "${data.external.lambda_files.result.source_dir}"
  output_path = "${path.cwd}/.terraform/tf-aws-asg-ebs-persist-${data.aws_caller_identity.current.account_id}-${var.env}-${var.stack_name}-${var.lambda_version}-management.zip"
}

resource "null_resource" "notifySNSTopic" {
  triggers {
    lambda_version = "${var.lambda_version}"
  }

  depends_on = ["aws_sns_topic_subscription.lambda_subscription"]

  provisioner "local-exec" {
    #Sends the  SNS Topic a notificiation that the ASG has been created. Works around dependency problem of SNS ASG notificiation cycle.
    command = "aws sns publish --region ${var.aws_region} --topic-arn ${var.sns_topic} --message \"{ \\\"Event\\\": \\\"autoscaling:TEST_NOTIFICATION\\\", \\\"AutoScalingGroupName\\\": \\\"${var.stack_name}\\\" }\""
  }
}

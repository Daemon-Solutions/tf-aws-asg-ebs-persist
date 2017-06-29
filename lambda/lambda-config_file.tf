# get current account id
data "aws_caller_identity" "current" {}

data "external" "lambda_files" {
  program = ["python2", "${path.module}/scripts/data.py"]

  query = {
    module_path     = "${path.module}"
    aws_acccount_id = "${data.aws_caller_identity.current.account_id}"
    asg_name        = "${var.asg_name}"

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
  source_dir  = "${data.external.lambda_files.result["source_dir"]}"
  output_path = "${path.cwd}/.terraform/tf-aws-asg-ebs-persist-${data.aws_caller_identity.current.account_id}-${var.asg_name}.zip"
}

# Sends the SNS Topic a notification that the ASG has been created.
# Works around dependency problem of SNS ASG notification cycle.
# Also uses the Lambda package's hash as a trigger so that settings
# changes will automatically trigger the same notification.
resource "null_resource" "notifySNSTopic" {
  triggers {
    source_code_hash = "${data.archive_file.lambda_package.output_base64sha256}"
  }

  depends_on = ["aws_sns_topic_subscription.lambda_subscription"]

  provisioner "local-exec" {
    command = "aws sns publish --region ${var.aws_region} --topic-arn ${var.sns_topic} --message \"{ \\\"Event\\\": \\\"autoscaling:TEST_NOTIFICATION\\\", \\\"AutoScalingGroupName\\\": \\\"${var.asg_name}\\\" }\""
  }
}

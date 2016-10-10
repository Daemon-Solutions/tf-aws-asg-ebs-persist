provider "aws" {
  region = "${var.aws_region}"
}

module "as_notification" {
  source           = "as_notification"
  sns_topic_arn    = "${module.sns.sns_topic_arn}"
  autoscaling_name = "${var.stack_instances["autoscaling_name"]}"
}

module "sns" {
  source     = "sns"
  env        = "${var.general["env"]}"
  stack_name = "${var.stack_instances.["stack_name"]}"
}

module "iam" {
  source     = "iam"
  env        = "${var.general["env"]}"
  stack_name = "${var.stack_instances.["stack_name"]}"
}

module "s3" {
  source      = "s3"
  env         = "${var.general["env"]}"
  client_name = "${var.general.["client_name"]}"
  aws_region  = "${var.aws_region}"
}

module "lambda" {
  source          = "lambda"
  client_name     = "${var.general["client_name"]}"
  env             = "${var.general["env"]}"
  sns_topic       = "${module.sns.sns_topic_arn}"
  stack_name      = "${var.stack_instances.["stack_name"]}"
  lambda_role_arn = "${module.iam.iam_role_lambda_arn}"
  lambda_version  = "${var.stack_instances.["lambda_version"]}"
  lambda_timeout  = "${var.stack_instances.["lambda_timeout"]}"
  volume_size     = ["${var.block_size}"]
  volume_type     = ["${var.block_type}"]
  volume_iops     = ["${var.block_iops}"]
  mount_point     = ["${var.mount_point}"]
  tag_name        = "${var.general["tag_value"]}"
  tag_value       = ["${var.tag_value}"]
  time_limit      = "${var.general["time_limit"]}"
}

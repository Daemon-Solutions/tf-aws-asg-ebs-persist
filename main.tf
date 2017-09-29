provider "aws" {
  region = "${var.aws_region}"
}

module "as_notification" {
  source           = "as_notification"
  sns_topic_arn    = "${module.sns.sns_topic_arn}"
  autoscaling_name = "${var.autoscaling_name}"
}

module "sns" {
  source     = "sns"
  env        = "${var.env}"
  stack_name = "${var.stack_name}"
}

module "iam" {
  source     = "iam"
  env        = "${var.env}"
  stack_name = "${var.stack_name}"
}

module "lambda" {
  source          = "lambda"
  env             = "${var.env}"
  sns_topic       = "${module.sns.sns_topic_arn}"
  stack_name      = "${var.stack_name}"
  lambda_role_arn = "${module.iam.iam_role_lambda_arn}"
  lambda_version  = "${var.lambda_version}"
  lambda_timeout  = "${var.lambda_timeout}"
  volume_size     = ["${var.block_size}"]
  volume_type     = ["${var.block_type}"]
  volume_iops     = ["${var.block_iops}"]
  mount_point     = ["${var.mount_point}"]
  tag_name        = "${var.tag_name}"
  tag_value       = ["${var.tag_value}"]
  time_limit      = "${var.time_limit}"
  encrypted       = "${var.encrypted}"
  aws_region      = "${var.aws_region}"
}

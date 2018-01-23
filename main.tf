provider "aws" {
  region = "${var.aws_region}"
}

module "as_notification" {
  source           = "as_notification"
  sns_topic_arn    = "${module.sns.sns_topic_arn}"
  autoscaling_name = "${var.asg_name}"
}

module "sns" {
  source   = "sns"
  asg_name = "${var.asg_name}"
}

module "iam" {
  source   = "iam"
  asg_name = "${var.asg_name}"
}

module "lambda" {
  source          = "lambda"
  sns_topic       = "${module.sns.sns_topic_arn}"
  asg_name        = "${var.asg_name}"
  lambda_role_arn = "${module.iam.iam_role_lambda_arn}"
  lambda_timeout  = "${var.lambda_timeout}"
  volume_size     = "${var.block_size}"
  volume_type     = "${var.block_type}"
  volume_iops     = "${var.block_iops}"
  mount_point     = "${var.mount_point}"
  tag_name        = "${var.tag_name}"
  tag_value       = "${var.tag_value}"
  extra_tags      = "${var.extra_tags}"
  time_limit      = "${var.time_limit}"
  encrypted       = "${var.encrypted}"
  aws_region      = "${var.aws_region}"
}

module "cw_event" {
  source        = "cw_event"
  asg_name      = "${var.asg_name}"
  function_arn  = "${module.lambda.arn}"
  function_name = "${module.lambda.name}"
}

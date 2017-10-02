provider "aws" {
  region = "${var.aws_region}"
}

resource "random_id" "suffix" {
  byte_length = 8
}

module "as_notification" {
  source           = "as_notification"
  sns_topic_arn    = "${module.sns.sns_topic_arn}"
  autoscaling_name = "${var.asg_name}"
}

module "sns" {
  source     = "sns"
  envname    = "${var.envname}"
  stack_name = "${var.asg_name}-${random_id.suffix.hex}"
}

module "iam" {
  source     = "iam"
  envname    = "${var.envname}"
  stack_name = "${var.asg_name}-${random_id.suffix.hex}"
}

module "lambda" {
  source          = "lambda"
  envname         = "${var.envname}"
  sns_topic       = "${module.sns.sns_topic_arn}"
  asg_name        = "${var.asg_name}"
  stack_name      = "${var.asg_name}-${random_id.suffix.hex}"
  lambda_role_arn = "${module.iam.iam_role_lambda_arn}"
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

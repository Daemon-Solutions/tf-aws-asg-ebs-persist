provider "aws" {
  region = "eu-west-1"
}

resource "aws_sns_topic" "new_topic" {
  name = "${var.asg_name}-ebs-persist"
}

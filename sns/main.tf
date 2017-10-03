resource "aws_sns_topic" "new_topic" {
  name = "${var.asg_name}-ebs-persist"
}

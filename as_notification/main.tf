resource "aws_autoscaling_notification" "new_notification" {
  group_names   = [var.autoscaling_name]
  topic_arn     = var.sns_topic_arn
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:TEST_NOTIFICATION",
  ]
}

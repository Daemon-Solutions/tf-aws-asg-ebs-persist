output "sns_topic_arn" {
  value = "${aws_sns_topic.new_topic.arn}"
}

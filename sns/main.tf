resource "aws_sns_topic" "new_topic" {
  name = "lambda-${var.env}-${var.stack_name}"
}

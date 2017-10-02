resource "aws_sns_topic" "new_topic" {
  name = "lambda-${var.envname}-${var.stack_name}"
}

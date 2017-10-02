resource "aws_lambda_function" "new_lambda" {
  filename         = "./.terraform/tf-aws-asg-ebs-persist-${data.aws_caller_identity.current.account_id}-${var.envname}-${var.stack_name}-management.zip"
  source_code_hash = "${data.archive_file.lambda_package.output_base64sha256}"
  function_name    = "lambda_as_ebs_${var.envname}_${var.stack_name}"
  role             = "${var.lambda_role_arn}"
  handler          = "main.lambda_handler"
  description      = "Lambda function to manage the EBS affinity for the stack ${var.stack_name} in ${var.envname} env"
  runtime          = "python2.7"
  timeout          = "${var.lambda_timeout}"
  depends_on       = ["data.archive_file.lambda_package"]
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn              = "${var.sns_topic}"
  protocol               = "lambda"
  endpoint_auto_confirms = "true"
  endpoint               = "${aws_lambda_function.new_lambda.arn}"
}

resource "aws_lambda_permission" "sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.new_lambda.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${var.sns_topic}"
}

output "lambda_function_id" {
  value = "${aws_lambda_function.new_lambda.arn}"
}

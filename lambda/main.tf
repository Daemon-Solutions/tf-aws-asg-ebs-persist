resource "aws_lambda_function" "new_lambda" {
  filename         = "${data.archive_file.lambda_package.output_path}"
  source_code_hash = "${data.archive_file.lambda_package.output_base64sha256}"
  function_name    = "${var.asg_name}-ebs-persist"
  role             = "${var.lambda_role_arn}"
  handler          = "main.lambda_handler"
  description      = "Lambda function to manage the EBS affinity for the ASG ${var.asg_name}"
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

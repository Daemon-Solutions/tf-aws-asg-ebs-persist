resource "aws_s3_bucket_object" "object" {
  bucket = "s3.lambdas.${var.env}.${var.client_name}"
  key    = "lambda_handler/lambda_as_ebs-${var.env}-${var.lambda_version}-management.zip"
  source = "/tmp/lambda_as_ebs-${var.env}-${var.lambda_version}-management.zip"
}

resource "aws_lambda_function" "new_lambda" {
  s3_bucket     = "s3.lambdas.${var.env}.${var.client_name}"
  s3_key        = "${aws_s3_bucket_object.object.id}"
  s3_object_version = "null" 
  function_name = "lambda_as_es_${var.env}_${var.stack_name}"
  role          = "${var.lambda_role_arn}"
  handler       = "main.lambda_handler"
  description   = "Lambda function to manage the EBS affinity for the stack ${var.stack_name} in ${var.env} env"
  runtime       = "python2.7"
  timeout       = "${var.lambda_timeout}"
  depends_on    =  ["null_resource.build_lambda_conf"]
}

resource "aws_sns_topic_subscription" "lambda_subscription" {
    topic_arn = "${var.sns_topic}"
    protocol = "lambda"
    endpoint_auto_confirms = "true"
    endpoint = "${aws_lambda_function.new_lambda.arn}"
}

resource "aws_lambda_permission" "sns" {
    statement_id = "AllowExecutionFromSNS"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.new_lambda.arn}"
    principal = "sns.amazonaws.com"
    source_arn = "${var.sns_topic}"
}

output "lambda_function_id" {
  value = "${aws_lambda_function.new_lambda.arn}"
}
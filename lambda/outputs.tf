output "arn" {
  value = "${aws_lambda_function.new_lambda.arn}"
}

output "name" {
  value = "${aws_lambda_function.new_lambda.function_name}"
}

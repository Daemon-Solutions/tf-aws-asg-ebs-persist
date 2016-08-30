output "iam_instance_profile_lambda" {
  value = "${aws_iam_instance_profile.lambda_profile.name}"
}

output "iam_role_lambda_arn" {
  value = "${aws_iam_role.lambda_iam.arn}"
}

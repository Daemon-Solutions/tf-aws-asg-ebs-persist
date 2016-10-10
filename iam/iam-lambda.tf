resource "aws_iam_role" "lambda_iam" {
  name               = "iam.${var.env}.lambda.${var.stack_name}"
  assume_role_policy = "${data.template_file.assume_role_policy_lambda.rendered}"
}

resource "aws_iam_instance_profile" "lambda_profile" {
  name  = "iam.${var.env}.lambda.${var.stack_name}"
  roles = ["${aws_iam_role.lambda_iam.name}"]
}

resource "aws_iam_role_policy" "lambda_pol" {
  name   = "policy.${var.env}.lambda.${var.stack_name}"
  role   = "${aws_iam_role.lambda_iam.id}"
  policy = "${data.template_file.role_policy_lambda.rendered}"
}

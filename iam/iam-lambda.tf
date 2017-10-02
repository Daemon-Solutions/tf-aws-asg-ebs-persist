resource "aws_iam_role" "lambda_iam" {
  name               = "iam.${var.envname}.lambda.${var.stack_name}"
  assume_role_policy = "${file("${path.module}/assume_role_policy_lambda.json")}"
}

resource "aws_iam_instance_profile" "lambda_profile" {
  name  = "iam.${var.envname}.lambda.${var.stack_name}"
  roles = ["${aws_iam_role.lambda_iam.name}"]
}

resource "aws_iam_role_policy" "lambda_pol" {
  name   = "policy.${var.envname}.lambda.${var.stack_name}"
  role   = "${aws_iam_role.lambda_iam.id}"
  policy = "${file("${path.module}/lambda_policy.json")}"
}

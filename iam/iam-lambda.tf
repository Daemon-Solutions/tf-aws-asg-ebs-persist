resource "aws_iam_role" "lambda_iam" {
  name               = "${var.asg_name}-ebs-persist"
  assume_role_policy = file("${path.module}/assume_role_policy_lambda.json")
}

resource "aws_iam_role_policy" "lambda_pol" {
  name   = "${var.asg_name}-ebs-persist"
  role   = aws_iam_role.lambda_iam.id
  policy = file("${path.module}/lambda_policy.json")
}

resource "template_file" "assume_role_policy_lambda" {
  template = "${file("${path.module}/assume_role_policy_lambda.tpl")}"
}

resource "template_file" "role_policy_lambda" {
  template = "${file("${path.module}/lambda_policy.tpl")}"
}

# Use CloudWatch events to invoke the Lambda function when an auto scaling
# group with lifecycle hooks has an instance enter the Pending:Wait state.

# Here is a scenario:
# 1. Instance enters Pending:Wait state
# 2. CloudWatch Event invokes Lambda function
# 3. Lambda function attaches EBS volume
# 4. Instance mounts EBS volume
# 5. Instance completes lifecycle hook
# 6. Instance enters InService state
# 7. ASG sends Instance Launched notification to SNS
# 8. SNS invokes Lambda function
# 9. Lambda function sees that EBS volume is already attached to instance

provider "aws" {
  region = "eu-west-1"
}

resource "aws_cloudwatch_event_rule" "events" {
  name = "${var.asg_name}-${var.suffix}"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-launch Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${var.asg_name}"
    ],
    "LifecycleTransition": [
      "autoscaling:EC2_INSTANCE_LAUNCHING"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "events" {
  target_id = "${var.asg_name}-${var.suffix}-events"
  rule      = "${aws_cloudwatch_event_rule.events.name}"
  arn       = "${var.function_arn}"
}

resource "aws_lambda_permission" "events" {
  statement_id  = "${var.asg_name}-${var.suffix}-events"
  action        = "lambda:InvokeFunction"
  function_name = "${var.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.events.arn}"
}

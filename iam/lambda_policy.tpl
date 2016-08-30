{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ec2:DescribeInstances",
                "ec2:DescribeVolumes",
                "ec2:DescribeVolumeStatus",
                "ec2:CreateTags",
                "ec2:AttachVolume",
                "ec2:DescribeSnapshots",
                "ec2:CreateSnapshot",
                "ec2:DetachVolume",
                "ec2:CreateVolume",
                "ec2:DeleteVolume",
		"autoscaling:DescribeAutoScalingGroups"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        }
    ]
}

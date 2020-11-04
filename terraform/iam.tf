data aws_iam_policy ReadOnlyAccess {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource aws_iam_role_policy_attachment scanner-read-only {
  role       = aws_iam_role.scanner.name
  policy_arn = data.aws_iam_policy.ReadOnlyAccess.arn
}

resource aws_iam_role scanner-invoker {
  name = "cloudmapper-scanner-invoker-role"

  # permit lambda to use this role
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "lambda.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    EOF
}

resource aws_iam_role_policy scanner-invoker {
  name = "cloudmapper-scanner-invoker-policy"
  role = aws_iam_role.scanner-invoker.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "sqs:GetQueueAttributes",
            "sqs:SendMessage"
          ],
          "Resource": "${aws_sqs_queue.queue.arn}"
        },
        {
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "ssm:PutParameter"
          ],
          "Resource": "arn:aws:ssm:eu-west-1:${data.aws_caller_identity.current.account_id}:parameter/cloudmapper-scanner/*"
        }
      ]
    }
    EOF
}

resource aws_iam_role scanner {
  name = "cloudmapper-scanner-role"

  # permit lambda to use this role
  assume_role_policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
    EOF
}

resource aws_iam_role_policy scanner {
  name = "cloudmapper-scanner-policy"
  role = aws_iam_role.scanner.id

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "sqs:GetQueueAttributes",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage"
          ],
          "Resource": "${aws_sqs_queue.queue.arn}"
        },
        {
          "Effect": "Allow",
          "Action": [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "ssm:GetParameters"
          ],
          "Resource": "arn:aws:ssm:eu-west-1:${data.aws_caller_identity.current.account_id}:parameter/cloudmapper-scanner/*"
        }
      ]
    }
    EOF
}

resource aws_sqs_queue_policy scanner {
  queue_url = aws_sqs_queue.queue.id
  policy    = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "sqs:GetQueueAttributes",
            "sqs:SendMessage"
          ],
          "Principal": {
            "AWS": "${aws_iam_role.scanner-invoker.arn}"
          }
        },
        {
          "Effect": "Allow",
          "Action": [
            "sqs:GetQueueAttributes",
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage"
          ],
          "Principal": {
            "AWS": "${aws_iam_role.scanner.arn}"
          }
        }
      ]
    }
    EOF
}

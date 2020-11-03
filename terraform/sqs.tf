resource aws_sqs_queue queue {
  name = "cloudmapper-scanner"

  visibility_timeout_seconds = local.lambda_timeout

  delay_seconds = local.scanner_delay_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource aws_sqs_queue dlq {
  name = "cloudmapper-scanner-dlq"
}

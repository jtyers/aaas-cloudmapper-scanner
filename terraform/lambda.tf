data aws_region current {}
data aws_caller_identity current {}

resource aws_lambda_function scanner-invoker {
  function_name = "cloudmapper-scanner-invoker"
  role          = aws_iam_role.scanner-invoker.arn

  handler                        = "handler.handler"
  runtime                        = "python3.7"
  timeout                        = 15
  reserved_concurrent_executions = 1

  environment {
    variables = {
      "SCANNER_QUEUE_URL" = aws_sqs_queue.queue.id
    }
  }

  filename         = var.scanner_invoker_function_zip
  source_code_hash = filebase64sha256(var.scanner_invoker_function_zip)

  depends_on = [
    aws_iam_role_policy_attachment.scanner-read-only,
  ]
}

resource aws_cloudwatch_log_group scanner-invoker {
  name              = "/aws/lambda/${aws_lambda_function.scanner-invoker.function_name}"
  retention_in_days = 7
}

#resource aws_lambda_function scanner {
#  function_name = "cloudmapper-scanner"
#  role          = aws_iam_role.scanner.arn
#
#  handler = "handler.handler"
#  runtime = "python3.7"
#  timeout = local.lambda_timeout
#
#  environment {
#    variables = {
#      "BUCKET_NAME" = aws_s3_bucket.result.bucket
#      "RANDOM_WAIT" = "5000"
#    }
#  }
#
#  filename         = var.scanner_function_zip
#  source_code_hash = filebase64sha256(var.scanner_function_zip)
#}
#
#resource aws_cloudwatch_log_group scanner {
#  name              = "/aws/lambda/${aws_lambda_function.scanner.function_name}"
#  retention_in_days = 7
#}

resource aws_s3_bucket result {
  bucket = "aaas-test-cloudmapper-results"

  lifecycle_rule {
    id      = "intelligent-tiering"
    enabled = true

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource aws_s3_bucket_policy result {
  bucket = aws_s3_bucket.result.bucket

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject"
          ],
          "Principal": {
            "AWS": "${aws_iam_role.scanner.arn}"
          },
          "Resource": "${aws_s3_bucket.result.arn}/*"
        }
      ]
    }
    EOF
}

resource aws_s3_bucket_public_access_block result {
  bucket = aws_s3_bucket.result.bucket

  block_public_acls   = true
  block_public_policy = true

  depends_on = [aws_s3_bucket.result]
}

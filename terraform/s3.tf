resource "aws_s3_bucket" "source-bucket" {
  bucket = "sallen-sentiment-source-bucket"
  
}
resource "aws_s3_bucket_policy" "source-bucket-policy" {
  bucket = aws_s3_bucket.source-bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3Access",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.lambda-role-comprehend.arn}"
      },
      "Action": [
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "${aws_s3_bucket.source-bucket.arn}",
        "${aws_s3_bucket.source-bucket.arn}/*"
      ]
    }
  ]
}
POLICY  
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.source-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.comprehend.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.lambda-comprehend-s3-permission]
}

resource "aws_s3_bucket_acl" "source-bucket-acl" {
  bucket = aws_s3_bucket.source-bucket.id
  acl    = "private"
}
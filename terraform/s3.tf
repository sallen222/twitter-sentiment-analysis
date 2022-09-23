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

resource "aws_s3_bucket" "destination-bucket" {
  bucket = "sallen-sentiment-destination-bucket"
}

resource "aws_s3_bucket_policy" "destination-bucket-policy" {
  bucket = aws_s3_bucket.destination-bucket.id
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
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.destination-bucket.arn}",
        "${aws_s3_bucket.destination-bucket.arn}/*"
      ]
    }
  ]
}
POLICY  
}

resource "aws_s3_bucket_acl" "destination-bucket-acl" {
  bucket = aws_s3_bucket.destination-bucket.id
  acl    = "private"
}
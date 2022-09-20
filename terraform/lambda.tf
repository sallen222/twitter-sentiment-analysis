data "archive_file" "lambda-comprehend" {
  type        = "zip"
  source_file = "../lambda/lambda_comprehend.py"
  output_path = "lambda_comprehend.zip"
}

resource "aws_lambda_permission" "apigw-lambda-get" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.comprehend.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.source-bucket.arn}"
}

resource "aws_lambda_function" "comprehend" {
  filename      = "lambda_comprehend.zip"
  function_name = "lambda_comprehend"
  role          = aws_iam_role.lambda-role-comprehend.arn
  handler       = "lambda_comprehend.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda-comprehend.output_base64sha256

  depends_on = [
    data.archive_file.lambda-comprehend
  ]
}

resource "aws_iam_role" "lambda-role-comprehend" {
  name = "lambda-role-comprehend"

  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_policy" "lambda-role-policy-comprehend" {
  name        = "lambda-role-policy-comprehend"
  description = "Policy for comprehend lambda"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging"
      ],
      "Resource": [
        "${aws_s3_bucket.source-bucket.arn}",
        "${aws_s3_bucket.destination-bucket.arn}"
      ], 
      "Effect": "Allow",
      "Sid": "AllowS3Access"
    },
    {
      "Action": [
        "comprehend:DetectSentiment",
        "comprehend:DetectDominantLanguage"
      ],
      "Resource": "*",
      "Effect": "Allow",
      "Sid": "AllowComprehend"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda-role-attachment-comprehend" {
  role       = aws_iam_role.lambda-role-comprehend.name
  policy_arn = aws_iam_policy.lambda-role-policy-comprehend.arn
}
data "archive_file" "lambda-comprehend" {
  type        = "zip"
  source_file = "../lambda/lambda_comprehend.py"
  output_path = "lambda_comprehend.zip"
}

resource "aws_lambda_permission" "lambda-comprehend-s3-permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.comprehend.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.source-bucket.id}"
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
        "comprehend:DetectSentiment",
        "comprehend:DetectDominantLanguage"
      ],
      "Resource": "*",
      "Effect": "Allow",
      "Sid": "AllowComprehend"
    },
    {
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": [
        "${data.aws_dynamodb_table.sentiment-table.arn}"
      ],
      "Effect": "Allow",
      "Sid": "AllowDynamoDB"    

    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda-role-attachment-comprehend" {
  role       = aws_iam_role.lambda-role-comprehend.name
  policy_arn = aws_iam_policy.lambda-role-policy-comprehend.arn
}

resource "aws_cloudwatch_log_group" "lambda-comprehend-log-group" {
  name = "/aws/lambda/${aws_lambda_function.comprehend.function_name}"
  retention_in_days = 7
}

resource "aws_iam_policy" "comprehend-logging-policy" {
  name = "comprehend-logging-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow",
      "Sid": "AllowLogging"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role = aws_iam_role.lambda-role-comprehend.id
  policy_arn = aws_iam_policy.comprehend-logging-policy.arn
}
data "aws_dynamodb_table" "sentiment-table" {
  name = "sentiment"
}

resource "aws_iam_policy" "dynamodb-policy" {
  name   = "dynamodb-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:Scan",
        "dynamodb:DescribeStream",
        "dynamodb:DescribeExport",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:DescribeTable",
        "dynamodb:DescribeContinuousBackups",
        "dynamodb:ExportTableToPointInTime",
        "dynamodb:UpdateTable",
        "dynamodb:UpdateContinuousBackups",
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "${data.aws_dynamodb_table.sentiment-table.arn}",
        "${data.aws_dynamodb_table.sentiment-table.arn}/stream/*",
        "${data.aws_dynamodb_table.sentiment-table.arn}/export/*",
        "arn:aws:s3:::<Your-Bucket-Name>",
        "arn:aws:s3:::<Your-Bucket-Name>/*"
      ]
    }
  ]
}
POLICY
}
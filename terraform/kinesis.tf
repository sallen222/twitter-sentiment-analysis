resource "aws_kinesis_stream" "twitter-stream" {
  name        = "twitter-stream"
  shard_count = 1

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "twitter-firehose" {
  name        = "twitter-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose-role.arn
    bucket_arn = aws_s3_bucket.source-bucket.arn

    # prefix using partitionkey from query
    prefix              = "data/key=!{partitionKeyFromQuery:key}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    buffer_size = 64
    dynamic_partitioning_configuration {
      enabled = true
    }
    processing_configuration {
      enabled = "true"

      # JQ processor
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{key:.key}"
        }
      }
    }
  }
}

resource "aws_iam_role" "firehose-role" {
  name = "firehose-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "firehose-policy" {
  name   = "firehose-policy"
  policy = <<POLICY
{
    "Version": "2012-10-17",  
    "Statement":
    [    
        {      
            "Effect": "Allow",      
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:PutObject"
            ],      
            "Resource": [        
                "${aws_s3_bucket.source-bucket.arn}",
                "${aws_s3_bucket.source-bucket.arn}/*"		    
            ]    
        },        
        {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetShardIterator",
                "kinesis:GetRecords",
                "kinesis:ListShards"
            ],
            "Resource": "${aws_kinesis_stream.twitter-stream.arn}"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "firehose-role-policy-attachment" {
  role       = aws_iam_role.firehose-role.name
  policy_arn = aws_iam_policy.firehose-policy.arn
}
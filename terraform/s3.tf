resource "aws_s3_bucket" "source-bucket" {
  bucket_prefix = "source-bucket"
}


resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.source-bucket.id
  acl    = "private"
}
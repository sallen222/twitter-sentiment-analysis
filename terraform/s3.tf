resource "aws_s3_bucket" "source-bucket" {
  bucket = "sallen-sentiment-source-bucket"
  
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.source-bucket.id
  acl    = "private"
}

resource "aws_s3_bucket" "destination-bucket" {
  bucket = "sallen-sentiment-destination-bucket"
}
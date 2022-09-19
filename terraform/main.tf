provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Application = "sentiment-analysis"
    }
  }

  access_key = var.aws-access-key
  secret_key = var.aws-secret-key
}
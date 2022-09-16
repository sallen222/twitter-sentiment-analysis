resource "aws_ssm_parameter" "bearer-token" {
  name  = "bearer_token"
  type  = "SecureString"
  value = var.twitter-bearer-token
}
resource "aws_ssm_parameter" "bearer-" {
  name  = "bearer_token"
  type  = "SecureString"
  value = var.twitter-bearer-token
}
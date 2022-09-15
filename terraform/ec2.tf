data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "tls_private_key" "private-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key-pair" {
  key_name   = var.key-name
  public_key = tls_private_key.private-key.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key-pair.key_name}.pem"
  content  = tls_private_key.private-key.private_key_pem
}

resource "aws_instance" "listener-instance" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.key-pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2-instance-profile.name

  user_data = <<EOF
    #!/bin/bash
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install python3 python3-pip git -y
    sudo pip3 install tweepy boto3 
    git clone https://github.com/sallen222/twitter-sentiment-analysis
    
EOF
}

resource "aws_iam_policy" "ec2-policy" {
  name   = "ec2-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1663164699427",
      "Action": [
        "kinesis:PutRecord"
      ],
      "Effect": "Allow",
      "Resource": "${aws_kinesis_stream.twitter-stream.arn}"
    }
  ]
}
POLICY
}

data "aws_iam_policy_document" "ec2-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2-role" {
  name               = "ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "ec2-role-policy-attachment" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = aws_iam_policy.ec2-policy.arn
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-role.name

}
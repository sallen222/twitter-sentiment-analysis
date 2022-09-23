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

  subnet_id = aws_subnet.subnet-1.id

  security_groups = [aws_security_group.twitter-sg.id]

  user_data = <<EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install python3 -y
    sudo apt-get install python3-pip -y
    sudo apt-get install git -y
    sudo pip3 install tweepy boto3 python-dotenv
    git clone https://github.com/sallen222/twitter-sentiment-analysis /home/ubuntu/twitter-sentiment-analysis
    cd /home/ubuntu/twitter-sentiment-analysis/stream-listener
    chmod +x twitter_listener.py
EOF
}

resource "aws_iam_policy" "ec2-policy" {
  name   = "ec2-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ssm:GetParameter"
      ],
      "Effect": "Allow",
      "Resource": "*"
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

resource "aws_iam_role_policy_attachment" "kinesis-role-policy-attachment" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = aws_iam_policy.ec2-policy.arn
}

resource "aws_iam_role_policy_attachment" "ssm-role-policy-attachment" {
  role       = aws_iam_role.ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2-instance-profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2-role.name
}
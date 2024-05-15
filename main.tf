/** Implemented by Crystal Lam **/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.49.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  id = "vpc-0afb4be1b6aeef8d9"
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.all.ids)
  id       = each.value
}

data "aws_s3_bucket" "quest" {
  bucket = "quest-lb-logs"
}

resource "aws_iam_instance_profile" "ec2_quest_instance_profile" {
  name = "ec2_quest_instance_profile"
  role = aws_iam_role.ec2_quest_role.name
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_quest_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        "Effect": "Allow",
        "Resource": ["arn:aws:ecr:us-east-1:211125577617:repository/quest"]
      }
    ]
  })
}

#iam role to assume for ec2 role
resource "aws_iam_role" "ec2_quest_role" {
  name = "ec2_quest_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF

  tags = {
    project = "quest_project"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

#ssh sg
module "dev_ssh_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2_ssh_sg"
  description = "Security group for ec2_sg"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["69.141.54.120/32"]
  ingress_rules       = ["ssh-tcp"]
}

#http-80 and https-443 sg and quest port 3000 same as grafana rule in module
module "ec2_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ec2_sg"
  description = "Security group for ec2_sg"
  vpc_id      = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "grafana-tcp"]
  egress_rules        = ["all-all"]
}

resource "aws_instance" "quest_app" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"

  root_block_device {
    volume_size = 8
  }

  vpc_security_group_ids = [
    module.ec2_sg.security_group_id,
    module.dev_ssh_sg.security_group_id
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_quest_instance_profile.name

  user_data = "${file("user-data.sh")}"

  tags = {
    Name = "quest-server"
    project = "quest-project"
  }

  key_name                = "quest_kp"
  monitoring              = true
  disable_api_termination = false
  ebs_optimized           = false
}

#incase instance dies, will always have same IP
resource "aws_eip" "quest_eip" {
  instance = aws_instance.quest_app.id
  domain   = "vpc"
}

#lb target group
resource "aws_lb_target_group" "quest_lb_tg" {
  name     = "quest-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    enabled = true
  }
}

#attach instance to target group
resource "aws_lb_target_group_attachment" "quest_tg_attachment" {
  target_group_arn = aws_lb_target_group.quest_lb_tg.arn
  target_id        = aws_instance.quest_app.id
  port             = 80
}

#quest lb
resource "aws_lb" "quest_lb" {
  name               = "quest-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.ec2_sg.security_group_id, module.dev_ssh_sg.security_group_id]
  subnets            = [for subnet in data.aws_subnets.all.ids : subnet]

  enable_deletion_protection = true

  tags = {
    project = "quest-project"
  }
}

#lb HTTP listener to forward to target groups
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.quest_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quest_lb_tg.arn
  }
}

#pending public cert validation
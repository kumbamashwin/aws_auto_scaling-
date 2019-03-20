provider "aws" {
  region = "ap-south-1"
}

variable "access_key" {
  type = "string"
}

variable "secret_key" {
  type = "string"
}

resource "aws_s3_bucket" "23_bucket" {
  bucket = "my-test-s3-terraform-bucket-01"
  acl    = "private-read"

  versioning {
    enabled = true
  }

  tags {
    Name = "my-test-s3-terraform-bucket-01"
  }
}

resource "aws_launch_configuration" "my_launch_config" {
  name_prefix          = "terraform-lc-example-"
  image_id             = "ami-03103e7ded4c02ef8"
  instance_type        = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}"
  provisioner "local-exec" {
    command =  echo hostname >> "test.txt"
    command = "aws s3 cp test.txt s3://my-test-s3-terraform-bucket-01/test2.txt"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_autoscale_group" {
  name                 = "terraform-asg-example"
  availability_zones   = ["ap-south-1a"]
  launch_configuration = "${aws_launch_configuration.my_launch_config.name}"
  min_size             = 1
  max_size             = 2

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = "${aws_iam_role.test_role.name}"
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.test_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

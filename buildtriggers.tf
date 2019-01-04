#
# Terraform backend settings - so we all share the same bucket
#

terraform {
  backend "s3" {
    bucket = "sl-terraform-backend"
    key = "terraform.tfstate"
    region = "eu-west-1"
  }
}

variable "aws_region" {
  default = "eu-west-1"
}

provider "aws" {
  region = "${var.aws_region}"
}

#
# CodeBuild roles
#

resource "aws_iam_role" "codebuild_role" {
  name = "${terraform.workspace}-codebuild-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_s3_bucket" "terraform-backend" {
  bucket = "sl-terraform-backend"
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "${terraform.workspace}-codebuild-policy"
  path = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  # TODO this policy grants too many permissions I think
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${data.aws_s3_bucket.terraform-backend.arn}",
        "${data.aws_s3_bucket.terraform-backend.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "s3:*",
        "iam:*",
        "lambda:*",
        "apigateway:*",
        "dynamodb:*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name = "${terraform.workspace}-codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles = [
    "${aws_iam_role.codebuild_role.id}"]
}

#
# CodeBuild configurations
#

resource "aws_codebuild_project" "build-code" {
  name = "${terraform.workspace}-build-code"
  description = "Run the build"
  build_timeout = "10"
  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/nodejs:10.14.1"
    type = "LINUX_CONTAINER"
  }

  source {
    type = "GITHUB"
    location = "https://github.com/blackmamo/${terraform.workspace}.git"
    git_clone_depth = 1
    report_build_status = true

    buildspec = "./buildspec.yml"
  }
}

resource "aws_codebuild_webhook" "build-code" {
  project_name = "${aws_codebuild_project.build-code.name}"
  branch_filter = "master"
}

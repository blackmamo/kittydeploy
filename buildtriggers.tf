/*
 * Inspired by https://github.com/nicolai86/awesome-codepipeline-ci
 */

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

variable "github_oauth_token" {
  type = "string"
  default = ""
}

variable "github_shared_secret" {
  type = "string"
  default = ""
}

variable "aws_account_id" {
  default = ""
}

//data "archive_file" "lambda_zip" {
//  type = "zip"
//  source_file = "src/pr-handler.js"
//  output_path = "build/pr-handler.zip"
//}
//
//#
//# AWS API Gateway - Used to register webhooks
//#
//
//
//resource "aws_api_gateway_rest_api" "gh" {
//  name = "github-hooks"
//  description = "api to handle github webhooks"
//  endpoint_configuration {
//    types = [
//      "REGIONAL"]
//  }
//}
//
//resource "aws_api_gateway_resource" "pr-handler" {
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  parent_id = "${aws_api_gateway_rest_api.gh.root_resource_id}"
//  path_part = "pr-handler"
//}
//
//resource "aws_api_gateway_method" "webhooks" {
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  resource_id = "${aws_api_gateway_resource.pr-handler.id}"
//  http_method = "POST"
//  authorization = "NONE"
//  request_parameters = {
//    "method.request.header.X-GitHub-Event" = true
//    "method.request.header.X-GitHub-Delivery" = true
//  }
//}
//
//resource "aws_api_gateway_integration" "webhooks" {
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  resource_id = "${aws_api_gateway_resource.pr-handler.id}"
//  http_method = "${aws_api_gateway_method.webhooks.http_method}"
//  integration_http_method = "POST"
//  type = "AWS"
//  uri = "${aws_lambda_function.pr-handler.invoke_arn}"
//  request_parameters = {
//    "integration.request.header.X-GitHub-Event" = "method.request.header.X-GitHub-Event"
//  }
//  request_templates = {
//    "application/json" = <<EOF
//{
//  "body" : $input.json('$'),
//  "header" : {
//    "X-GitHub-Event": "$input.params('X-GitHub-Event')",
//    "X-GitHub-Delivery": "$input.params('X-GitHub-Delivery')"
//  }
//}
//EOF
//  }
//}
//
//resource "aws_api_gateway_integration_response" "webhook" {
//
//  depends_on = [
//    "aws_api_gateway_integration.webhooks"]
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  resource_id = "${aws_api_gateway_resource.pr-handler.id}"
//  http_method = "${aws_api_gateway_integration.webhooks.http_method}"
//  status_code = "200"
//
//  response_templates {
//    "application/json" = "$input.path('$')"
//  }
//
//  response_parameters = {
//    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
//    "method.response.header.Access-Control-Allow-Origin" = "'*'"
//  }
//}
//
//resource "aws_api_gateway_integration_response" "error" {
//
//  depends_on = [
//    "aws_api_gateway_integration.webhooks"]
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  resource_id = "${aws_api_gateway_resource.pr-handler.id}"
//  http_method = "${aws_api_gateway_integration.webhooks.http_method}"
//  status_code = "500"
//
//  response_templates {
//    "application/json" = "internal error!"
//  }
//
//  response_parameters = {
//    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
//    "method.response.header.Access-Control-Allow-Origin" = "'*'"
//  }
//
//  selection_pattern = ".+"
//}
//
//resource "aws_api_gateway_method_response" "200" {
//  depends_on = [
//    "aws_api_gateway_method.webhooks"]
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  resource_id = "${aws_api_gateway_resource.pr-handler.id}"
//  http_method = "${aws_api_gateway_method.webhooks.http_method}"
//  status_code = "200"
//  response_parameters = {
//    "method.response.header.Content-Type" = true
//    "method.response.header.Access-Control-Allow-Origin" = true
//  }
//}
//
//resource "aws_api_gateway_method_response" "500" {
//  depends_on = [
//    "aws_api_gateway_method.webhooks"]
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  resource_id = "${aws_api_gateway_resource.pr-handler.id}"
//  http_method = "${aws_api_gateway_method.webhooks.http_method}"
//  status_code = "500"
//  response_parameters = {
//    "method.response.header.Content-Type" = true
//    "method.response.header.Access-Control-Allow-Origin" = true
//  }
//}
//
//resource "aws_api_gateway_deployment" "gh" {
//  depends_on = [
//    "aws_api_gateway_method.webhooks",
//    "aws_api_gateway_integration_response.webhook",
//    "aws_api_gateway_method_response.200"]
//
//  rest_api_id = "${aws_api_gateway_rest_api.gh.id}"
//  stage_name = "test"
//  // See https://github.com/hashicorp/terraform/issues/6613#issuecomment-322264393
//  stage_description = "${md5(file("buildtriggers.tf"))}"
//}

#
# AWS Lamda - called by github on PR
#

//resource "aws_iam_policy" "pr-handler-policy" {
//  name = "pr-handler-policy"
//  path = "/"
//  description = "lambda pr policy"
//  policy = <<EOF
//{
//    "Version": "2012-10-17",
//    "Statement": [
//        {
//            "Sid": "Stmt1476919244000",
//            "Effect": "Allow",
//            "Action": [
//                "codepipeline:CreatePipeline",
//                "codepipeline:DeletePipeline",
//                "codepipeline:GetPipelineState",
//                "codepipeline:ListPipelines",
//                "codepipeline:GetPipeline",
//                "codepipeline:UpdatePipeline",
//                "iam:PassRole"
//            ],
//            "Resource": [
//                "*"
//            ]
//        },
//        {
//          "Effect": "Allow",
//          "Action": [
//            "logs:CreateLogGroup",
//            "logs:CreateLogStream",
//            "logs:PutLogEvents"
//          ],
//          "Resource": "arn:aws:logs:*:*:*"
//        }
//    ]
//}
//EOF
//}
//
//resource "aws_iam_role" "pr-handler" {
//  name = "pr-handler"
//  assume_role_policy = <<EOF
//{
//  "Version": "2012-10-17",
//  "Statement": [
//    {
//      "Action": "sts:AssumeRole",
//      "Principal": {
//        "Service": "lambda.amazonaws.com"
//      },
//      "Effect": "Allow",
//      "Sid": ""
//    }
//  ]
//}
//EOF
//}
//
//resource "aws_iam_role_policy_attachment" "pr-handler-attach" {
//  role = "${aws_iam_role.pr-handler.name}"
//  policy_arn = "${aws_iam_policy.pr-handler-policy.arn}"
//}

//resource "aws_lambda_function" "pr-handler" {
//  filename = "${data.archive_file.lambda_zip.output_path}"
//  function_name = "pr-handler"
//  role = "${aws_iam_role.pr-handler.arn}"
//  handler = "pr-handler.handler"
//  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
//  memory_size = 256
//  timeout = 300
//  runtime = "nodejs8.10",
//  environment {
//    variables = {
//      PIPELINE_TEMPLATE = "${aws_codepipeline.ci.name}",
//      GITHUB_OAUTH_TOKEN = "${var.github_oauth_token}"
//    }
//  }
//}


//resource "aws_lambda_permission" "apigw_lambda" {
//  statement_id = "AllowExecutionFromAPIGateway"
//  action = "lambda:InvokeFunction"
//  function_name = "${aws_lambda_function.pr-handler.arn}"
//  principal = "apigateway.amazonaws.com"
//
//  source_arn = "${aws_api_gateway_rest_api.gh.execution_arn}/*/POST/pr-handler"
//}

#
# CodeBuild roles
#

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-"

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

resource "aws_iam_policy" "codebuild_policy" {
  name = "codebuild-policy"
  path = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

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
        "${aws_s3_bucket.ci.arn}",
        "${aws_s3_bucket.ci.arn}/*"
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
        "logs:PutLogEvents"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name = "codebuild-policy-attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles = [
    "${aws_iam_role.codebuild_role.id}"]
}

#
# CodeBuild configurations
#

resource "aws_codebuild_project" "build-code" {
  name = "build-code"
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
    location = "https://github.com/blackmamo/test.git"
    git_clone_depth = 1
    report_build_status = true

    buildspec = "./buildspec.yml"
  }
}

resource "aws_codebuild_webhook" "build-code" {
  project_name = "${aws_codebuild_project.build-code.name}"
  branch_filter = "master"
}

resource "aws_s3_bucket" "ci" {
  bucket = "sl-github-hook-codepipeline-ci-bucket"
  acl = "private"
}

resource "aws_iam_role" "ci" {
  name = "test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = "${aws_iam_role.ci.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.ci.arn}",
        "${aws_s3_bucket.ci.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

#
# CodePipeline configurations
#

//resource "aws_codepipeline" "ci" {
//  name     = "pr-template"
//  role_arn = "${aws_iam_role.ci.arn}"
//
//  artifact_store {
//    location = "${aws_s3_bucket.ci.bucket}"
//    type     = "S3"
//  }
//
//  stage {
//    name = "Build"
//
//    action {
//      name            = "Build"
//      category        = "Build"
//      owner           = "AWS"
//      provider        = "CodeBuild"
//      version         = "1"
//
//      configuration {
//        ProjectName = "${aws_codebuild_project.build-code.name}"
//      }
//    }
//  }
//}

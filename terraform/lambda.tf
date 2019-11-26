locals {
  callback_lambda_filepath = "../callback-output.zip"
  welcome_lambda_filepath = "../welcome-output.zip"
}

variable "region" {
  type = string
  default = "us-east-2"
}

variable "GITHUB_CLIENT_ID" {
  type = string
}
variable "GITHUB_CLIENT_SECRET" {
  type = string
}
variable "GITHUB_TEMPLATE_REPO_OWNER_NAME" {
  type = string
}
variable "GITHUB_TEMPLATE_REPO_NAME" {
  type = string
  default = "ReDup"
}

resource "aws_lambda_function" "callback" {
  filename = local.callback_lambda_filepath
  function_name = "redup-callback-function"

  handler = "lambda-callback.lambda_callback.lambda_handler"
  runtime = "python3.8"
  memory_size = "512"
  timeout = 10

  source_code_hash = filebase64sha256(local.callback_lambda_filepath)
  role = aws_iam_role.iam_for_redup.arn
  environment {
    variables = {
      CLIENT_ID = var.GITHUB_CLIENT_ID
      CLIENT_SECRET = var.GITHUB_CLIENT_SECRET
      GITHUB_URL = "https://github.com"
      GITHUB_API_URL = "https://api.github.com"
      GITHUB_TEMPLATE_REPO_OWNER_NAME = var.GITHUB_TEMPLATE_REPO_OWNER_NAME
      GITHUB_TEMPLATE_REPO_NAME = var.GITHUB_TEMPLATE_REPO_NAME
      GITHUB_DUPLICATE_REPO_NAME = "ReDup"
      GITHUB_DUPLICATE_REPO_DESCRIPTION = "An instance of repository copied by ReDup ©2019 Andrii Gryshchenko. For more details please see https://github.com/azurefireice/ReDup."
    }
  }
}

resource "aws_lambda_function" "welcome" {
  filename = local.welcome_lambda_filepath
  function_name = "redup-welcome-function"

  handler = "lambda-welcome.lambda_welcome.lambda_handler"
  runtime = "python3.8"
  memory_size = "256"
  timeout = 3

  source_code_hash = filebase64sha256(local.welcome_lambda_filepath)
  role = aws_iam_role.iam_for_redup.arn
  environment {
    variables = {
      CLIENT_ID = var.GITHUB_CLIENT_ID
      GITHUB_URL = "https://github.com"
    }
  }
}

resource "aws_lambda_permission" "apigw_callback" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.callback.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.redup_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_welcome" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.welcome.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.redup_api.execution_arn}/*/*"
}
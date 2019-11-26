locals {
  default_content_handling = "CONVERT_TO_TEXT"
  default_passthrough_behavior = "WHEN_NO_MATCH"
  default_response_templates = {
    "application/json" = "$input.json('$')"
  }
  default_error_template = {
    "application/json" = "$input.path('$.errorMessage')"
  }
}


resource "aws_api_gateway_rest_api" "redup_api" {
  name = "ReDup"
}

resource "aws_api_gateway_resource" "redup_root" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  parent_id = aws_api_gateway_rest_api.redup_api.root_resource_id
  path_part = "redup"
}

resource "aws_api_gateway_method" "redup_root_method" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.redup_root.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "redup_root_response_200" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.redup_root.id
  http_method = aws_api_gateway_method.redup_root_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "redup_root_response_200_integration" {
  depends_on = [
    aws_api_gateway_integration.redup_root_lambda_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.redup_root.id
  http_method = aws_api_gateway_method.redup_root_method.http_method
  status_code = aws_api_gateway_method_response.redup_root_response_200.status_code
  selection_pattern = ""
  response_templates = local.default_response_templates
  content_handling = local.default_content_handling
}

resource "aws_api_gateway_integration" "redup_root_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.redup_root.id
  http_method = aws_api_gateway_method.redup_root_method.http_method
  integration_http_method = "POST"

  type = "AWS_PROXY"
  uri = aws_lambda_function.welcome.invoke_arn
}

###                     ###
### Callback            ###
###                     ###
resource "aws_api_gateway_resource" "callback_resource" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  parent_id = aws_api_gateway_resource.redup_root.id
  path_part = "callback"
}

resource "aws_api_gateway_method" "callback_method" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.callback_resource.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "callback_response_200" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.callback_resource.id
  http_method = aws_api_gateway_method.callback_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "callback_response_500" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.callback_resource.id
  http_method = aws_api_gateway_method.callback_method.http_method
  status_code = "500"
}

resource "aws_api_gateway_integration_response" "callback_response_200_integration" {
  depends_on = [
    aws_api_gateway_integration.callback_lambda_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.callback_resource.id
  http_method = aws_api_gateway_method.callback_method.http_method
  status_code = aws_api_gateway_method_response.callback_response_200.status_code
  selection_pattern = ""
  response_templates = local.default_response_templates
  content_handling = local.default_content_handling
}

resource "aws_api_gateway_integration_response" "callback_response_500_integration" {
  depends_on = [
    aws_api_gateway_integration.callback_lambda_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.callback_resource.id
  http_method = aws_api_gateway_method.callback_method.http_method
  status_code = aws_api_gateway_method_response.callback_response_500.status_code
  selection_pattern = ".*error.*"
  response_templates = local.default_response_templates
  content_handling = local.default_content_handling
}

resource "aws_api_gateway_request_validator" "callback_request_validator" {
  name = "callback validator"
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "callback_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  resource_id = aws_api_gateway_resource.callback_resource.id
  http_method = aws_api_gateway_method.callback_method.http_method
  integration_http_method = "POST"

  type = "AWS_PROXY"
  uri = aws_lambda_function.callback.invoke_arn
  /*request_parameters = {
    "integration.request.querystring.code" = "method.request.querystring.code"
  }
*/
  /*  request_templates = {
      "application/json" = <<EOF
  { "code": "$input.params('code')" }
  EOF
    }*/
  /*
    passthrough_behavior = local.default_passthrough_behavior
    content_handling     = local.default_content_handling*/
}


###                     ###
###     Deployment      ###
###                     ###
resource "aws_api_gateway_deployment" "redup_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.callback_lambda_integration,
    aws_api_gateway_integration.redup_root_lambda_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.redup_api.id
  stage_name = "prod"
}

output "homepage_url" {
  value = join("/", [
    aws_api_gateway_deployment.redup_api_deployment.invoke_url,
    aws_api_gateway_resource.redup_root.path_part
  ])
}

output "auth_redirect_url" {
  depends_on = [
    homepage_url]
  value = join("/", [
    aws_api_gateway_deployment.redup_api_deployment.invoke_url,
    aws_api_gateway_resource.redup_root.path_part,
    aws_api_gateway_resource.callback_resource.path_part
  ])
}
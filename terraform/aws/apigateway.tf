###########################################
################ Guess API ################
###########################################

resource "aws_api_gateway_rest_api" "guess_api" {
  name = "guess_api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "guess_resource" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  parent_id = aws_api_gateway_rest_api.guess_api.root_resource_id
  path_part = "guess"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "post_response" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  status_code = "200"
  depends_on = [aws_api_gateway_method.post_method]
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = aws_api_gateway_method.post_method.http_method
  integration_http_method = aws_api_gateway_method.post_method.http_method
  uri = aws_lambda_function.guess_function.invoke_arn
  type = "AWS_PROXY"
}

resource "aws_api_gateway_deployment" "guess_v1" {
  depends_on = [aws_api_gateway_integration.post_integration]
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  stage_name = "v1"
}

###########################################
############## CORS Support ###############
###########################################

resource "aws_api_gateway_method" "cors_method" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_integration" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = aws_api_gateway_method.cors_method.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = <<EOF
{ "statusCode": 200 }
EOF
  }
}

resource "aws_api_gateway_method_response" "cors_method_response" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.guess_api.id
  resource_id = aws_api_gateway_resource.guess_resource.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = aws_api_gateway_method_response.cors_method_response.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST'"
    "method.response.header.Access-Control-Allow-Origin" = "'http://${aws_s3_bucket.the_song_is.website_endpoint}'"
  }
}
  
/*
module "apigateway_cors" {
  source = "bridgecrewio/apigateway-cors/aws"
  version = "1.1.0"
  api = aws_api_gateway_rest_api.guess_api.id
  resources = [aws_api_gateway_resource.guess_resource.id]
  methods = ["POST"]
}
*/
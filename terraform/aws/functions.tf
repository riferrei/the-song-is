resource "null_resource" "build_functions" {
  provisioner "local-exec" {
    command = "sh build.sh"
    interpreter = ["bash", "-c"]
    working_dir = "../../aws-functions"
  }
}

###########################################
############# Guess Function ##############
###########################################

resource "aws_iam_role_policy" "guess_policy" {
  role = aws_iam_role.guess_role.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "guess_role" {
  name = "guess_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "guess_function" {
  depends_on = [
    null_resource.build_functions,
    aws_iam_role.guess_role]
  function_name = "guess"
  filename = "../../aws-functions/deploy/guess-1.0.jar"
  handler = "io.confluent.cloud.GuessHandler"
  role = aws_iam_role.guess_role.arn
  runtime = "java8"
  memory_size = 512
  timeout = 60
  environment {
    variables = {
      BOOTSTRAP_SERVERS = "${var.ccloud_broker_list}"
      CLUSTER_API_KEY = "${var.ccloud_access_key}"
      CLUSTER_API_SECRET = "${var.ccloud_secret_key}"
    }
  }
}

resource "aws_lambda_permission" "api_gateway_trigger" {
  statement_id = "AllowExecutionFromApiGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guess_function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.guess_api.execution_arn}/*/*/*"
}

resource "aws_lambda_permission" "guess_cloudwatch_trigger" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.guess_function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.guess_every_five_minutes.arn
}

resource "aws_cloudwatch_event_rule" "guess_every_five_minutes" {
    name = "execute-guess-every-five-minutes"
    description = "Execute the guess function every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "guess_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.guess_every_five_minutes.name
    target_id = "guess_function"
    arn = aws_lambda_function.guess_function.arn
    input = data.template_file.guess_intent.rendered
}

data "template_file" "guess_intent" {
  template = file("templates/guessintent.json")
}

###########################################
############ Winner Function ##############
###########################################

resource "aws_iam_role_policy" "winner_policy" {
  role = aws_iam_role.winner_role.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "winner_role" {
  name = "winner_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "winner_function" {
  depends_on = [
    null_resource.build_functions,
    aws_iam_role.winner_role]
  function_name = "winner"
  filename = "../../aws-functions/deploy/winner.zip"
  handler = "bin/winner"
  role = aws_iam_role.winner_role.arn
  runtime = "go1.x"
  memory_size = 128
  timeout = 5
  environment {
    variables = {
      REDIS_HOST = join(",",formatlist("%s", aws_instance.redis_server.*.private_ip),)
      REDIS_PORT = "6379"
    }
  }
  vpc_config {
      security_group_ids = [aws_security_group.redis_server[0].id]
      subnet_ids = aws_subnet.private_subnet.*.id
  }
}

resource "aws_lambda_permission" "winner_alexa_trigger" {
  statement_id 	= "AllowExecutionFromAlexa"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.winner_function.function_name
  principal = "alexa-appkit.amazon.com"
  event_source_token = var.winner_skill_id
}

resource "aws_lambda_permission" "winner_cloudwatch_trigger" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.winner_function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.winner_every_five_minutes.arn
}

resource "aws_cloudwatch_event_rule" "winner_every_five_minutes" {
    name = "execute-winner-every-five-minutes"
    description = "Execute the winner function every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "winner_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.winner_every_five_minutes.name
    target_id = "winner_function"
    arn = aws_lambda_function.winner_function.arn
    input = data.template_file.winner_intent.rendered
}

data "template_file" "winner_intent" {
  template = file("templates/winnerintent.json")
}

###########################################
########## DeleteKeys Function ############
###########################################

resource "aws_iam_role_policy" "deletekeys_policy" {
  role = aws_iam_role.deletekeys_role.name
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "deletekeys_role" {
  name = "deletekeys_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "deletekeys_function" {
  depends_on = [
    null_resource.build_functions,
    aws_iam_role.deletekeys_role]
  function_name = "deletekeys"
  filename = "../../aws-functions/deploy/deletekeys.zip"
  handler = "bin/deletekeys"
  role = aws_iam_role.deletekeys_role.arn
  runtime = "go1.x"
  memory_size = 128
  timeout = 5
  environment {
    variables = {
      REDIS_HOST = join(",",formatlist("%s", aws_instance.redis_server.*.private_ip),)
      REDIS_PORT = "6379"
    }
  }
  vpc_config {
      security_group_ids = [aws_security_group.redis_server[0].id]
      subnet_ids = aws_subnet.private_subnet.*.id
  }
}

resource "aws_lambda_permission" "deletekeys_alexa_trigger" {
  statement_id 	= "AllowExecutionFromAlexa"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deletekeys_function.function_name
  principal = "alexa-appkit.amazon.com"
  event_source_token = var.delete_keys_skill_id
}

resource "aws_lambda_permission" "deletekeys_cloudwatch_trigger" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.deletekeys_function.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.deletekeys_every_five_minutes.arn
}

resource "aws_cloudwatch_event_rule" "deletekeys_every_five_minutes" {
    name = "execute-deletekeys-every-five-minutes"
    description = "Execute the deletekeys function every five minutes"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "deletekeys_every_five_minutes" {
    rule = aws_cloudwatch_event_rule.deletekeys_every_five_minutes.name
    target_id = "deletekeys_function"
    arn = aws_lambda_function.deletekeys_function.arn
    input = data.template_file.deletekeys_intent.rendered
}

data "template_file" "deletekeys_intent" {
  template = file("templates/deletekeysintent.json")
}
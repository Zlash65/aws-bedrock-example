locals {
  tags = {
    Terraform = true
    Team      = "zlash65"
    Repo      = "https://github.com/Zlash65/aws-bedrock-example"
  }
}

resource "aws_iam_role" "main" {
  name = "aws-bedrock-example-lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_s3_bucket" "main" {
  bucket = "zlash65-aws-bedrock-example"
}

resource "aws_iam_policy" "s3" {
  name = "aws-bedrock-example-lambda-s3-role"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.s3.arn
}

resource "aws_iam_policy" "bedrock" {
  name = "aws-bedrock-example-lambda-bedrock"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "bedrock:InvokeModel"
        ],
        Resource = "arn:aws:bedrock:*::foundation-model/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.bedrock.arn
}

resource "aws_lambda_function" "main" {
  function_name    = "aws-bedrock-example"
  role             = aws_iam_role.main.arn
  handler          = "app.handler"
  runtime          = "python3.11"
  filename         = "${path.module}/../lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda.zip")
  timeout          = 180

  depends_on = [
    aws_iam_role_policy_attachment.main,
    aws_iam_role_policy_attachment.s3
  ]
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "aws-bedrock-example"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.main.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "generate_dockerfile_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /generate-dockerfile"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

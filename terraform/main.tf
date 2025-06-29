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

resource "aws_lambda_function" "main" {
  function_name    = "aws-bedrock-example"
  role             = aws_iam_role.main.arn
  handler          = "app.handler"
  runtime          = "python3.11"
  filename         = "${path.module}/../lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda.zip")
  timeout          = 180
}

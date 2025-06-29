output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.bucket
}

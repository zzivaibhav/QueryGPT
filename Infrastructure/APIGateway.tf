# # Create API Gateway
# resource "aws_api_gateway_rest_api" "rag_api" {
#   name        = "RAG-API"
#   description = "API Gateway for RAG application"
# }

# # Create /index resource
# resource "aws_api_gateway_resource" "index" {
#   rest_api_id = aws_api_gateway_rest_api.rag_api.id
#   parent_id   = aws_api_gateway_rest_api.rag_api.root_resource_id
#   path_part   = "index"
# }

# # Create POST method
# resource "aws_api_gateway_method" "index_post" {
#   rest_api_id   = aws_api_gateway_rest_api.rag_api.id
#   resource_id   = aws_api_gateway_resource.index.id
#   http_method   = "POST"
#   authorization = "NONE"
# }

# # Create integration with Lambda
# resource "aws_api_gateway_integration" "lambda_integration" {
#   rest_api_id = aws_api_gateway_rest_api.rag_api.id
#   resource_id = aws_api_gateway_resource.index.id
#   http_method = aws_api_gateway_method.index_post.http_method
  
#   integration_http_method = "POST"
#   type                   = "AWS_PROXY"
#   uri                    = aws_lambda_function.indexing_lambda_function.invoke_arn
# }

# # Create deployment
# resource "aws_api_gateway_deployment" "api_deployment" {
#   rest_api_id = aws_api_gateway_rest_api.rag_api.id
  
#   depends_on = [
#     aws_api_gateway_integration.lambda_integration
#   ]
# }

# # Create stage
# resource "aws_api_gateway_stage" "api_stage" {
#   deployment_id = aws_api_gateway_deployment.api_deployment.id
#   rest_api_id   = aws_api_gateway_rest_api.rag_api.id
#   stage_name    = "dev"
# }

# # Add Lambda permission for API Gateway
# resource "aws_lambda_permission" "api_gateway_lambda" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.indexing_lambda_function.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.rag_api.execution_arn}/*/*"
# }

# # Output the API Gateway URL
# output "api_gateway_url" {
#   value = "${aws_api_gateway_stage.api_stage.invoke_url}/index"
# }

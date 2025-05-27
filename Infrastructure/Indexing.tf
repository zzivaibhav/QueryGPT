# #Archive the data before the creation of the Lambda funtion
# data "archive_file" "lambda" {
#   type        = "zip"
#   source_file = "${path.module}/Lambdas/Indexing.py"
#   output_path = "${path.module}/Archives/Indexing.zip"
# }

# # Create IAM role for the Lambda function
# # This role allows the Lambda function to assume the necessary permissions to execute
# resource "aws_iam_role" "indexing_lambda_role" {
#   name = "indexing_lambda_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # Attach basic Lambda execution policy
# resource "aws_iam_role_policy_attachment" "lambda_basic" {
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   role       = aws_iam_role.indexing_lambda_role.name
# }

# # Lambda function for AWS HealthScribe processing
# resource "aws_lambda_function" "indexing_lambda_function" {
#   function_name = "IndexingFunction"
#   description   = "Lambda function to curate and index the SQL schemas in the vector database."
  
#   runtime       = "python3.12"
#   handler       = "Indexing.lambda_handler"
  
#   filename         = data.archive_file.lambda.output_path
#   source_code_hash = data.archive_file.lambda.output_base64sha256
  
#   timeout     = 900  # 15 minutes
#   memory_size = 256

#   environment {
#     variables = {
#       QDRANT_HOST = "your-qdrant-host"  # Replace with actual Qdrant host
#       QDRANT_PORT = "6333"
#     }
#   }

#   role       = aws_iam_role.indexing_lambda_role.arn
#   depends_on = [data.archive_file.lambda, aws_iam_role_policy_attachment.lambda_basic]
# }


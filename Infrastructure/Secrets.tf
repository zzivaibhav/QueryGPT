data "aws_secretsmanager_secret" "llm_ip" {
  name = "prod/llm"
}

resource "aws_secretsmanager_secret_version" "llm_ip" {
  secret_id     = data.aws_secretsmanager_secret.llm_ip.id
  secret_string = jsonencode({
     
    llm_endpoint = aws_instance.llm_instance.public_ip
    llm_port = 11434
  })
}

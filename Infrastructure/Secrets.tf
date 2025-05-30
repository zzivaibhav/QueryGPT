data "aws_secretsmanager_secret" "llm_ip" {
  name = "prod/QGpt"
}

resource "aws_secretsmanager_secret_version" "llm_ip" {
  secret_id     = data.aws_secretsmanager_secret.llm_ip.id
  secret_string = jsonencode({
     OLLAMA_HOST = "http://${aws_instance.llm_instance.private_ip}:11434"
     QDRANT_HOST = "http://${aws_lb.qdrant_lb.dns_name}"
     QDRANT_PORT = 6333
  })
}

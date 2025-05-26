# EC2 hosting a LLM
resource "aws_instance" "llm_instance" {
  ami           = "ami-0953476d60561c955"
  instance_type = "t3.large"    # Changed from t2.small for better performance

  root_block_device {
    volume_size           = 30    # Increased from 8GB to 30GB
    volume_type          = "gp3"  # Changed to gp3 for better performance
    delete_on_termination = true
  }

  tags = {
    Name = "LLM-Instance"
  }

 user_data = <<-EOF
  #!/bin/bash
  set -e

  # Log to a file for debugging
  exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

  echo "Updating system packages..."
  yum update -y

  echo "Installing Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh

  export HOME=/root

  # Create systemd override for Ollama to listen on all interfaces
  mkdir -p /etc/systemd/system/ollama.service.d
  printf "[Service]\\nEnvironment=\\\"OLLAMA_HOST=0.0.0.0\\\"\\n" > /etc/systemd/system/ollama.service.d/override.conf

  systemctl daemon-reload
  systemctl enable ollama
  systemctl restart ollama

  # Wait for Ollama service to be fully started
  sleep 10

  echo "Pulling deepseek-coder:1.3b model (this may take a while)..."
  ollama pull deepseek-coder:1.3b

  echo "Setup complete! To test, run: ollama run deepseek-coder:1.3b"

  ollama run deepseek-coder:1.3b || true
EOF


  lifecycle {
    create_before_destroy = true
  }

  # Add required security group rule to access Ollama API
  vpc_security_group_ids = [aws_security_group.llm_security_group.id]
}

# Create security group for LLM instance
resource "aws_security_group" "llm_security_group" {
  name        = "llm_security_group"
  description = "Security group for LLM instance"

  ingress {
    from_port   = 11434  # Ollama API port
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Be more restrictive in production
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH access, restrict to your IP in production
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "llm_security_group"
  }
}

output "llm_instance_ip" {
  value = aws_instance.llm_instance.public_ip
}
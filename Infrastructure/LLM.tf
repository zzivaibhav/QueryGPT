# Security Group for LLM instances
resource "aws_security_group" "llm_security_group" {
  name        = "llm-security-group"
  description = "Security group for LLM instances"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from within the VPC
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.llm_lb_security_group.id]  # Allow traffic from load balancer only
  }
  ingress {
    from_port   =  22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access from anywhere (consider restricting this in production)
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
  tags = {
    Name = "LLM-Security-Group"
  }
}

# Security Group for the Load Balancer
resource "aws_security_group" "llm_lb_security_group" {
  name        = "llm-lb-security-group"
  description = "Security group for LLM Load Balancer"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = {
    Name = "LLM-LB-Security-Group"
  }
}

# Application Load Balancer
resource "aws_lb" "llm_lb" {
  name               = "llm-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.llm_lb_security_group.id]
  subnets            = [aws_subnet.querygpt_public_subnet.id, aws_subnet.querygpt_public_subnet_standby.id]
  idle_timeout       = 3600  # Set idle timeout to 1 hour (3600 seconds)

  enable_deletion_protection = false

  tags = {
    Name = "LLM-Load-Balancer"
  }
}

# Target Group for LLM instances
resource "aws_lb_target_group" "llm_target_group" {
  name     = "llm-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.querygpt_vpc.id
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/api/health"
    port                = "traffic-port"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Register LLM instance with the target group
resource "aws_lb_target_group_attachment" "llm_target_group_attachment" {
  target_group_arn = aws_lb_target_group.llm_target_group.arn
  target_id        = aws_instance.llm_instance.id
  port             = 8080
}

# Add listener for the load balancer
resource "aws_lb_listener" "llm_listener" {
  load_balancer_arn = aws_lb.llm_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.llm_target_group.arn
  }
}

# EC2 Instance
resource "aws_instance" "llm_instance" {
  ami                    = "ami-0953476d60561c955"
  instance_type          = "t3.xlarge"
  subnet_id              = aws_subnet.LLM_private_subnet.id
  vpc_security_group_ids = [aws_security_group.llm_security_group.id]
  associate_public_ip_address = true
  iam_instance_profile   = aws_iam_instance_profile.llm_instance_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Log to a file for debugging
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    echo "Updating system packages..."
    yum update -y

    # Install and configure Docker
    echo "Installing Docker..."
    yum install -y docker
    systemctl start docker
    systemctl enable docker

    # Install AWS CLI and jq if not already installed
    echo "Installing AWS CLI and jq..."
    yum install -y aws-cli jq

    # Fetching the secrets 
    echo "Retrieving secrets from Secrets Manager..."
    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id prod/QGpt --region us-east-1 | jq -r '.SecretString')
    
    # Extract environment variables from secret JSON
    echo "DEBUG: Secret JSON content:"
    echo "$SECRET_JSON" | jq '.'
    
    # Set environment variables with default fallbacks if not found
    OLLAMA_HOST=$(echo "$SECRET_JSON" | jq -r '.OLLAMA_HOST // "http://localhost:11434"')
    QDRANT_HOST=$(echo "$SECRET_JSON" | jq -r '.QDRANT_HOST // "http://'"${aws_lb.qdrant_lb.dns_name}"'"')
    QDRANT_PORT=$(echo "$SECRET_JSON" | jq -r '.QDRANT_PORT // "6333"')

    # Validate secrets - use defaults if necessary, but don't fail
    if [ "$OLLAMA_HOST" = "null" ]; then
        echo "⚠️ WARNING: OLLAMA_HOST is null. Using default: http://localhost:11434"
        OLLAMA_HOST="http://localhost:11434"
    fi
    
    if [ "$QDRANT_HOST" = "null" ]; then
        echo "⚠️ WARNING: QDRANT_HOST is null. Using load balancer DNS name instead."
        QDRANT_HOST="http://${aws_lb.qdrant_lb.dns_name}"
    fi
    
    if [ "$QDRANT_PORT" = "null" ]; then
        echo "⚠️ WARNING: QDRANT_PORT is null. Using default: 6333"
        QDRANT_PORT="6333"
    fi

    echo "✅ Using OLLAMA_HOST: $OLLAMA_HOST"
    echo "✅ Using QDRANT_HOST: $QDRANT_HOST" 
    echo "✅ Using QDRANT_PORT: $QDRANT_PORT"

    # Pull and run the application container
    echo "Pulling and running the application container..."
    docker pull vaibhav1476/query
    docker run -d \
      --name queryapp \
      -p 8080:8080 \
      -e OLLAMA_HOST=$OLLAMA_HOST \
      -e QDRANT_HOST=$QDRANT_HOST \
      -e QDRANT_PORT=$QDRANT_PORT \
      vaibhav1476/query

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
     
    ollama run codellama:7b 
  EOF

  tags = {
    Name = "LLM-App-Combined-Instance"
  }
}

# IAM role for the EC2 instance
resource "aws_iam_role" "llm_instance_role" {
  name = "llm-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy to allow access to Secrets Manager
resource "aws_iam_policy" "secrets_access_policy" {
  name        = "secrets-access-policy"
  description = "Policy to allow access to specific secrets in Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = data.aws_secretsmanager_secret.llm_ip.arn
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "secrets_policy_attachment" {
  role       = aws_iam_role.llm_instance_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}

# Create instance profile
resource "aws_iam_instance_profile" "llm_instance_profile" {
  name = "llm-instance-profile"
  role = aws_iam_role.llm_instance_role.name
}

# Output the instance public IP
output "llm_instance_ip" {
  value = aws_instance.llm_instance.public_ip
}

# Add output for application access
output "app_access_url" {
  value = "http://${aws_instance.llm_instance.public_ip}:8080"
}
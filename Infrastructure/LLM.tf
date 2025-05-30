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
    cidr_blocks = ["0.0.0.0/0"]  # Allow application access
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

# EC2 Instance
resource "aws_instance" "llm_instance" {
  ami                    = "ami-0953476d60561c955"
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.querygpt_public_subnet.id
  vpc_security_group_ids = [aws_security_group.llm_security_group.id]
  associate_public_ip_address = true

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

    # Pull and run the application container
    echo "Pulling and running the application container..."
    docker pull vaibhav1476/query
    docker run -d \
      --name queryapp \
      -p 8080:8080 \
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
    ollama pull deepseek-coder:1.3b
    ollama run deepseek-coder:1.3b
    
    
    # Output container network information to a file for reference
    echo "Creating network binding information file..."
    echo "---------------------------------------------" > /home/ec2-user/container_info.txt
    echo "Query App Container Network Binding:" >> /home/ec2-user/container_info.txt
    docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' queryapp >> /home/ec2-user/container_info.txt
    echo "External access: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080" >> /home/ec2-user/container_info.txt
    echo "Internal access: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8080" >> /home/ec2-user/container_info.txt
    echo "---------------------------------------------" >> /home/ec2-user/container_info.txt
    echo "Ollama Service:" >> /home/ec2-user/container_info.txt
    echo "External access: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):11434" >> /home/ec2-user/container_info.txt
    echo "Internal access: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):11434" >> /home/ec2-user/container_info.txt
    
    # Make the file accessible to all users
    chmod 644 /home/ec2-user/container_info.txt
  EOF

  tags = {
    Name = "LLM-App-Combined-Instance"
  }
}

# Output the instance public IP
output "llm_instance_ip" {
  value = aws_instance.llm_instance.public_ip
}

# Add output for application access
output "app_access_url" {
  value = "http://${aws_instance.llm_instance.public_ip}:8080"
}

# Add output for container network binding information
output "container_network_info" {
  value = <<-EOT
    # Connect to the EC2 instance:
    ssh ec2-user@${aws_instance.llm_instance.public_ip}
    
    # View container network binding information:
    cat /home/ec2-user/container_info.txt
    
    # Or use this command to get Docker container IP directly:
    docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' queryapp
  EOT
}
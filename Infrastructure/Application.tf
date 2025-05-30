# Security Group for Application instance
resource "aws_security_group" "app_security_group" {
  name        = "app-security-group"
  description = "Security group for Application instance"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from anywhere for testing
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH access for testing
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App-Security-Group"
  }
}

# EC2 Instance - Commented out as we're running the application on the LLM instance
/*
resource "aws_instance" "app_instance" {
  ami           = "ami-0953476d60561c955"  # Amazon Linux 2023 AMI
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.querygpt_public_subnet.id
  
  vpc_security_group_ids = [aws_security_group.app_security_group.id]
  associate_public_ip_address = true

 root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker

              # Pull and run the container
              docker pull vaibhav1476/query
              docker run -d \
                --name queryapp \
                -p 8080:8080 \
                vaibhav1476/query
              EOF
  )

  tags = {
    Name = "App-Instance"
  }
}

# Output the instance's public IP - Commented out
output "app_public_ip" {
  value = aws_instance.app_instance.public_ip
}
*/
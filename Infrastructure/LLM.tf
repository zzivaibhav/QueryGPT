
# Security Group for LLM instances
resource "aws_security_group" "llm_security_group" {
  name        = "llm-security-group"
  description = "Security group for LLM instances"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Allow access from within the VPC
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
# Launch Template for LLM instances

resource "aws_launch_template" "llm_launch_template" {
  name_prefix   = "llm-launch-template"
  image_id      = "ami-0953476d60561c955"
  instance_type = "t3.large"

  network_interfaces {
    associate_public_ip_address = true
    security_groups            = [aws_security_group.llm_security_group.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type          = "gp3"
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
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
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "LLM-Instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "llm_asg" {
  name                = "llm-asg"
  desired_capacity    = 2
  max_size           = 4
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.llm.arn]
  vpc_zone_identifier = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]

  launch_template {
    id      = aws_launch_template.llm_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "LLM-Instance"
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "llm_alb" {
  name               = "llm-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.llm_alb_sg.id]
  subnets           = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]
}

# ALB Target Group
resource "aws_lb_target_group" "llm" {
  name     = "llm-target-group"
  port     = 11434
  protocol = "HTTP"
  vpc_id   = aws_vpc.querygpt_vpc.id

  health_check {
    enabled             = true
    path                = "/health"
    port               = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# ALB Listener
resource "aws_lb_listener" "llm" {
  load_balancer_arn = aws_lb.llm_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.llm.arn
  }
}

# ALB Security Group
resource "aws_security_group" "llm_alb_sg" {
  name        = "llm-alb-sg"
  description = "Security group for LLM ALB"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Update the output to show the ALB DNS instead of instance IP
output "llm_endpoint" {
  value = aws_lb.llm_alb.dns_name
}
# Security Group for Application instances
resource "aws_security_group" "app_security_group" {
  name        = "app-security-group"
  description = "Security group for Application instances"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
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

# Launch Template for Application instances
resource "aws_launch_template" "app_launch_template" {
  name_prefix   = "app-launch-template"
  image_id      = "ami-0953476d60561c955"  # Amazon Linux 2023 AMI
  instance_type = "t3.medium"

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [aws_security_group.app_security_group.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e

              # Add logging for debugging
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              # Update system packages
              dnf update -y

              # Install Docker
              dnf install docker -y

              # Start and enable Docker service
              systemctl start docker
              systemctl enable docker

              # Add ec2-user to docker group
              usermod -a -G docker ec2-user

              # Pull and run the application container
               docker pull vaibhav1476/querygpt:latest
             docker run -d \
                -p 8080:8080 \
                -e QDRANT_HOST=${aws_lb.llm_alb.dns_name} \
                -e QDRANT_PORT=6333 \
                vaibhav1476/querygpt:latest
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "App-Instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_alb_sg.id]
  subnets           = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]
}

# ALB Target Group
resource "aws_lb_target_group" "app" {
  name     = "app-target-group"
  port     = 8080
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

# Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg"
  desired_capacity    = 2
  max_size           = 4
  min_size           = 1
  target_group_arns  = [aws_lb_target_group.app.arn]
  vpc_zone_identifier = [aws_subnet.App_private_subnet.id]

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "App-Instance"
    propagate_at_launch = true
  }
}

# ALB Listener
resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ALB Security Group
resource "aws_security_group" "app_alb_sg" {
  name        = "app-alb-sg"
  description = "Security group for Application ALB"
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

# Output the ALB DNS name
output "app_endpoint" {
  value = aws_lb.app_alb.dns_name
}
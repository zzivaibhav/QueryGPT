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
# Install system updates and core dependencies
yum update -y
yum install -y git python3

# (Optional, but recommended) Install pip for Python 3
python3 -m ensurepip --upgrade

# Clone your repository
cd /home/ec2-user
git clone https://github.com/zzivaibhav/QueryGPT.git

# (Optional) Adjust permissions
chown -R ec2-user:ec2-user /home/ec2-user/QueryGPT

# Go into your repo
cd /home/ec2-user/QueryGPT/backend

# (Optional, but recommended) Set up Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python requirements (update requirements.txt in repo as needed)
pip install --upgrade pip
pip install -r requirements.txt

# Export Flask variables (update main.py if your entrypoint is different)
export FLASK_APP=main.py
export FLASK_ENV=production
# (Optional: set host/port if your app runs on different ports)
export FLASK_RUN_HOST=0.0.0.0
export FLASK_RUN_PORT=8080

# Run the Flask server in the background (stdout/stderr to a log file)
nohup flask run --host=0.0.0.0 --port=8080 > flask.log 2>&1 &

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
  vpc_zone_identifier = [aws_subnet.querygpt_public_subnet.id]  # Changed to public subnet

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
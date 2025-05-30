resource "aws_ecs_cluster" "qdrant_cluster" {
  name = "qdrant-cluster"
}

resource "aws_ecs_task_definition" "qdrant_task" {
  family                   = "qdrant"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 1024
  memory                  = 2048

  volume {
    name = "qdrant-storage"
    efs_volume_configuration {
      file_system_id = data.aws_efs_file_system.qdrant_efs.id
      root_directory = "/"
      transit_encryption = "ENABLED"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "qdrant"
      image     = "qdrant/qdrant:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
      mountPoints = [
        {
          sourceVolume  = "qdrant-storage"
          containerPath = "/qdrant/storage"
          readOnly     = false
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:6333/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      portMappings = [
        {
          containerPort = 6333
          hostPort      = 6333
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_security_group" "qdrant_sg" {
  name        = "qdrant-sg"
  description = "Security group for Qdrant service"
  vpc_id      = aws_vpc.querygpt_vpc.id

  tags = {
    Name = "qdrant-sg"
  }
  ingress {
    from_port   = 6333
    to_port     = 6333
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

resource "aws_security_group" "alb_sg" {
  name        = "qdrant-alb-sg"
  description = "Security group for Qdrant ALB"
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

resource "aws_lb" "qdrant" {
  name               = "qdrant-alb"
  internal           = true  # Change to internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]  # Use private subnets
}

resource "aws_lb_target_group" "qdrant" {
  name        = "qdrant-target-group"
  port        = 6333
  protocol    = "HTTP"
  vpc_id      = aws_vpc.querygpt_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/healthz"
    port               = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "qdrant" {
  load_balancer_arn = aws_lb.qdrant.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.qdrant.arn
  }
}

resource "aws_ecs_service" "qdrant_service" {
  name            = "qdrant-service"
  cluster         = aws_ecs_cluster.qdrant_cluster.id
  task_definition = aws_ecs_task_definition.qdrant_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]
    security_groups  = [aws_security_group.qdrant_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.qdrant.arn
    container_name   = "qdrant"
    container_port   = 6333
  }

  depends_on = [aws_lb_listener.qdrant]
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_efs_file_system" "qdrant_efs" {
  tags = {
    Name = "qdrant-efs"
  }
  depends_on = [aws_efs_file_system.qdrant_efs]
}

output "Vector_DB_Endpoint" {
  value = aws_lb.qdrant.dns_name
}
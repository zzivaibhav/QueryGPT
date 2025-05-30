resource "aws_ecs_task_definition" "query_task" {
  family                   = "query"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 2048  # 2 vCPU
  memory                  = 4096  # 4GB memory

  container_definitions = jsonencode([
    {
      name      = "query"
      image     = "vaibhav1476/query:latest"
      cpu       = 2048
      memory    = 4096
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      # healthCheck = {
      #   command     = ["CMD-SHELL", "curl -f http://localhost:8080/api/health || exit 1"]
      #   interval    = 30
      #   timeout     = 5
      #   retries     = 3
      #   startPeriod = 60
      # }
    }
  ])
}

resource "aws_security_group" "query_sg" {
  name        = "query-sg"
  description = "Security group for Query service"
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
    Name = "query-sg"
  }
}

resource "aws_lb_target_group" "query" {
  name        = "query-target-group"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.querygpt_vpc.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/api/health"
    port               = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb" "query_alb" {
  name               = "query-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.query_sg.id]
  subnets           = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]
}

resource "aws_lb_listener" "query" {
  load_balancer_arn = aws_lb.query_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.query.arn
  }
}

resource "aws_ecs_service" "query_service" {
  name            = "query-service"
  cluster         = aws_ecs_cluster.qdrant_cluster.id  # Using the same cluster as Qdrant
  task_definition = aws_ecs_task_definition.query_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.VectorDB_private_subnet.id, aws_subnet.App_private_subnet.id]
    security_groups  = [aws_security_group.query_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.query.arn
    container_name   = "query"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.query]
}

output "Query_Service_Endpoint" {
  value = aws_lb.query_alb.dns_name
}

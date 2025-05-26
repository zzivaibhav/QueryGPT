resource "aws_ecs_cluster" "qdrant_cluster" {
  name = "qdrant-cluster"
}

resource "aws_ecs_task_definition" "qdrant_task" {
  family                   = "qdrant"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 1024
  memory                  = 2048

  container_definitions = jsonencode([
    {
      name      = "qdrant"
      image     = "qdrant/qdrant:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
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

//to do: Harden the security group rules
resource "aws_security_group" "qdrant_sg" {
  name        = "qdrant-sg"
  description = "Security group for Qdrant service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 6333
    to_port     = 6333
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

//to do: Add tags to the VPC
//to do: Make the Subnet private as this is gonna be used for the Qdrant service
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}


resource "aws_lb" "qdrant" {
  name               = "qdrant-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets           = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "qdrant" {
  name        = "qdrant-target-group"
  port        = 6333
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
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
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.qdrant_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.qdrant.arn
    container_name   = "qdrant"
    container_port   = 6333
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

//to do: Harden the route table rules
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group_rule" "qdrant_from_alb" {
  type                     = "ingress"
  from_port               = 6333
  to_port                 = 6333
  protocol                = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id       = aws_security_group.qdrant_sg.id
}

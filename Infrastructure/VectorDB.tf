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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "qdrant_service" {
  name            = "qdrant-service"
  cluster         = aws_ecs_cluster.qdrant_cluster.id
  task_definition = aws_ecs_task_definition.qdrant_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {

    subnets          = [aws_subnet.VectorDB_private_subnet.id]
    security_groups  = [aws_security_group.qdrant_sg.id]
    assign_public_ip = false
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create the EFS file system for Qdrant data persistence
resource "aws_efs_file_system" "qdrant_efs" {
  creation_token = "qdrant-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true
  
  tags = {
    Name = "qdrant-efs"
  }
}

# Create mount target for EFS in the public subnet
resource "aws_efs_mount_target" "qdrant_efs_mount" {
  file_system_id = aws_efs_file_system.qdrant_efs.id
  subnet_id      = aws_subnet.VectorDB_private_subnet.id
  security_groups = [aws_security_group.efs_sg.id]
}

# Security group for EFS
resource "aws_security_group" "efs_sg" {
  name        = "efs-security-group"
  description = "Security group for EFS mount targets"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port   = 2049  # NFS port
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.qdrant_sg.id]  # Allow access from Qdrant tasks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "efs-security-group"
  }
}

# Fix the data source to directly use the resource instead of searching by tag
data "aws_efs_file_system" "qdrant_efs" {
  file_system_id = aws_efs_file_system.qdrant_efs.id
}

output "Vector_DB_Info" {
  value = "Qdrant service is running in ECS. Access it directly via tasks in the qdrant-cluster."
  description = "Information about the Vector DB service"
}

output "qdrant_efs_id" {
  value = aws_efs_file_system.qdrant_efs.id
  description = "ID of the EFS file system used for Qdrant storage"
}

output "qdrant_access_instructions" {
  value = "To access Qdrant, use the task's private IP on port 6333. You can find this in the AWS Console under ECS > Clusters > qdrant-cluster > Tasks."
}
 
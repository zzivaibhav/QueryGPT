resource "aws_efs_file_system" "qdrant_efs" {
  creation_token = "qdrant-efs"
  encrypted      = true

  tags = {
    Name = "qdrant-efs"
  }
}

resource "aws_efs_mount_target" "qdrant_efs_mount" {
  count           = 1  # Changed from 2 to 1 since we only have one subnet
  file_system_id  = aws_efs_file_system.qdrant_efs.id
  subnet_id       = aws_subnet.VectorDB_private_subnet.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  name        = "qdrant-efs-sg"
  description = "Security group for Qdrant EFS"
  vpc_id      = aws_vpc.querygpt_vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.qdrant_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc" "querygpt_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "querygpt_vpc"
  }
  enable_dns_support = true
  enable_dns_hostnames = true
  
}

//public subnet for NAT gateways and load balancers
resource "aws_subnet" "querygpt_public_subnet" {
  vpc_id            = aws_vpc.querygpt_vpc.id
  cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"  # Modify as needed
  tags = {
    Name = "querygpt_public_subnet"
  }
}

// Internet gateway for the public subnet
resource "aws_internet_gateway" "querygpt_igw" {
  vpc_id = aws_vpc.querygpt_vpc.id
  tags = {
    Name = "querygpt_igw"
  }
}

// Route table for the public subnet
resource "aws_route_table" "querygpt_public_route_table" {
  vpc_id = aws_vpc.querygpt_vpc.id

     route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.querygpt_igw.id
  }
 
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
 }
  tags = {
    Name = "querygpt_public_route_table"
  }
}

// Associate the public subnet with the route table
resource "aws_route_table_association" "querygpt_public_subnet_association" {
  subnet_id      = aws_subnet.querygpt_public_subnet.id
  route_table_id = aws_route_table.querygpt_public_route_table.id
}

// standby public subnet for LB
resource "aws_subnet" "querygpt_public_subnet_standby" {
  vpc_id            = aws_vpc.querygpt_vpc.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "us-east-1b"  # Modify as needed
  tags = {
    Name = "querygpt_public_subnet_standby"
  }
}
// Associate the standby public subnet with the route table
resource "aws_route_table_association" "querygpt_public_subnet_association_standby" {
  subnet_id      = aws_subnet.querygpt_public_subnet_standby.id
  route_table_id = aws_route_table.querygpt_public_route_table.id
}
//EIP for the NAT gateway
resource "aws_eip" "querygpt_nat_eip" {
   
  tags = {
    Name = "querygpt_nat_eip"
  }
}
// NAT gateway in the public subnet
resource "aws_nat_gateway" "querygpt_nat_gateway" {
  allocation_id = aws_eip.querygpt_nat_eip.id
  subnet_id     = aws_subnet.querygpt_public_subnet.id
  tags = {
    Name = "querygpt_nat_gateway"
  }
}


// Private subnet for the LLM instance
resource "aws_subnet" "LLM_private_subnet" {
  vpc_id            = aws_vpc.querygpt_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"  # Modify as needed
  tags = {
    Name = "LLM_private_subnet"
  }
}

// Route table for the LLM private subnet
resource "aws_route_table" "LLM_private_route_table" {
  vpc_id = aws_vpc.querygpt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.querygpt_nat_gateway.id
  }
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
  tags = {
    Name = "LLM_private_route_table"
  }
}
// Associate the LLM private subnet with the route table
resource "aws_route_table_association" "LLM_private_subnet_association" {
  subnet_id      = aws_subnet.LLM_private_subnet.id
  route_table_id = aws_route_table.LLM_private_route_table.id
}

// Private subnet for the VectorDB instance
resource "aws_subnet" "VectorDB_private_subnet" {
  vpc_id            = aws_vpc.querygpt_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"  # Modify as needed
  tags = {
    Name = "VectorDB_private_subnet"
  }
}

//route table for vactordb private subnet
resource "aws_route_table" "VectorDB_private_route_table" {
  vpc_id = aws_vpc.querygpt_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.querygpt_nat_gateway.id
  }
  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  } 
    tags = {
        Name = "VectorDB_private_route_table"
    }
}

// Associate the VectorDB private subnet with the route table
resource "aws_route_table_association" "VectorDB_private_subnet_association" {
  subnet_id      = aws_subnet.VectorDB_private_subnet.id
  route_table_id = aws_route_table.VectorDB_private_route_table.id
}

//Private subnet for Application server
 

// Route table for the Application private subnet
 
// Associate the Application private subnet with the route table
 
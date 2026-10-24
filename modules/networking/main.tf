# =============================================================
# MODULE: networking
# What it does: Creates a VPC with public and private subnets
# Why: EC2 runs in private subnet = more secure
# =============================================================

# VPC = Virtual Private Cloud
# Think of it as your own private network inside AWS
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr        # IP range for the whole network
  enable_dns_hostnames = true                 # allows DNS names for instances
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Internet Gateway = the door between your VPC and the internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# PUBLIC subnet — for load balancers (has internet access)
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  # false = instances do NOT get a public IP automatically (safer)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-public-${count.index + 1}"
    Environment = var.environment
    Type        = "public"
  }
}

# PRIVATE subnet — for EC2 instances (no direct internet access)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.project_name}-private-${count.index + 1}"
    Environment = var.environment
    Type        = "private"
  }
}

# Route table for public subnets — sends traffic to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                      # all traffic
    gateway_id = aws_internet_gateway.main.id       # goes to internet
  }

  tags = {
    Name        = "${var.project_name}-rt-public"
    Environment = var.environment
  }
}

# Connect public subnets to the public route table
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

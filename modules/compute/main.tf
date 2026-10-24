# =============================================================
# MODULE: compute
# What it does: Creates EC2 instance with security group + IAM role
# Security: private subnet, least-privilege IAM, no SSH from internet
# =============================================================

# Security Group = firewall rules for the EC2 instance
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for EC2 instance — least privilege"
  vpc_id      = var.vpc_id

  # INBOUND rules — who can connect TO this instance?
  # Only allow HTTPS from inside the VPC (not from internet)
  ingress {
    description = "HTTPS from VPC only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # only from within the VPC
  }

  # OUTBOUND rules — where can this instance connect TO?
  # Allow HTTPS out — needed to call AWS services (S3, SSM)
  egress {
    description = "HTTPS to internet (for AWS API calls)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# IAM Role = identity for the EC2 instance
# This allows EC2 to call AWS APIs (like S3) without storing credentials
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  # Trust policy: who can use this role?
  # Answer: only EC2 instances
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = var.environment
  }
}

# IAM Policy = what actions the EC2 can do
# LEAST PRIVILEGE: only read/write to its own S3 bucket
resource "aws_iam_role_policy" "ec2_s3" {
  name = "${var.project_name}-ec2-s3-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow: read and write to the project S3 bucket only
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        # Allow: SSM Session Manager — for secure access without SSH keys
        Effect   = "Allow"
        Action   = ["ssm:UpdateInstanceInformation", "ssmmessages:*"]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile = attaches the role to the EC2 instance
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Get the latest Amazon Linux 2 AMI automatically
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance — runs in private subnet
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id    # PRIVATE subnet
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # No SSH key — use SSM Session Manager instead (more secure)
  # key_name = "my-key"  ← we intentionally leave this out

  # Encrypt the root disk
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size_gb
    encrypted             = true   # encrypt at rest
    delete_on_termination = true
  }

  # Disable IMDS v1 — force use of IMDSv2 (security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # forces IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

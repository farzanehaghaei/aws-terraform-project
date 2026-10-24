# =============================================================
# ENVIRONMENT: dev
# This file calls all 3 modules and connects them together
# =============================================================

# Step 1: Create the network first
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["eu-central-1a", "eu-central-1b"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
}

# Step 2: Create the S3 bucket
module "storage" {
  source = "../../modules/storage"

  project_name = var.project_name
  environment  = var.environment
  bucket_name  = "${var.project_name}-${var.environment}-data"
}

# Step 3: Create the EC2 instance
# Uses outputs from networking and storage modules
module "compute" {
  source = "../../modules/compute"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id           # from networking
  vpc_cidr          = "10.0.0.0/16"
  private_subnet_id = module.networking.private_subnet_ids[0]  # from networking
  s3_bucket_name    = module.storage.bucket_name         # from storage
  instance_type     = "t3.micro"
  root_volume_size_gb = 20
}

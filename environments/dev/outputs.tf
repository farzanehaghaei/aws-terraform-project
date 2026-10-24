output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = module.compute.instance_id
}

output "s3_bucket_name" {
  description = "S3 Bucket name"
  value       = module.storage.bucket_name
}

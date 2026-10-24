output "vpc_id"          { value = module.networking.vpc_id }
output "ec2_instance_id" { value = module.compute.instance_id }
output "s3_bucket_name"  { value = module.storage.bucket_name }

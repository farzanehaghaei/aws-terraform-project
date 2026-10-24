output "instance_id"       { value = aws_instance.main.id }
output "security_group_id" { value = aws_security_group.ec2.id }
output "iam_role_arn"      { value = aws_iam_role.ec2.arn }

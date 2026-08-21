# export the region
output "region" {
  value = var.region
}

# export the project name
output "project_name" {
  value = var.project_name
}

# export the environment
output "environment" {
  value = var.environment
}

# export the vpc id
output "vpc_id" {
  value = aws_vpc.vpc.id
}

# export the internet gateway
output "internet_gateway" {
  value = aws_internet_gateway.internet_gateway.id
}

# export the public subnet az1 id
output "public_subnet_az1_id" {
  value = aws_subnet.public_subnet_az1.id
}

# export the public subnet az2 id
output "public_subnet_az2_id" {
  value = aws_subnet.public_subnet_az2.id
}

# export the private app subnet az1 id
output "private_app_subnet_az1_id" {
  value = aws_subnet.private_app_subnet_az1.id
}

# export the private app subnet az2 id
output "private_app_subnet_az2_id" {
  value = aws_subnet.private_app_subnet_az2.id
}

# export the private data subnet az1 id
output "private_data_subnet_az1_id" {
  value = aws_subnet.private_data_subnet_az1.id
}

# export the private data subnet az2 id
output "private_data_subnet_az2_id" {
  value = aws_subnet.private_data_subnet_az2.id
}

# export the first availability zone
output "availability_zone_1" {
  value = data.aws_availability_zones.available_zones.names[0]
}

# export the second availability zone
output "availability_zone_2" {
  value = data.aws_availability_zones.available_zones.names[1]
}

# export the alb target group arn
output "alb_target_group_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}

# export the application load balancer dns name
output "application_load_balancer_dns_name" {
  value = aws_lb.application_load_balancer.dns_name
}

# export the application load balancer zone id
output "application_load_balancer_zone_id" {
  value = aws_lb.application_load_balancer.zone_id
}

# export ecr repository uri
output "ecr_repository_uri" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

#export runner security group id
output "runner_security_group_id" {
  value = aws_security_group.runner_security_group.id
}
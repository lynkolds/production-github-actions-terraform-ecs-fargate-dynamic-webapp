# Global variables
variable "region" {
  description = "AWS region to deploy resources in"
}

variable "project_name" {
  description = "Project name used in resource names"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
}

# VPC networking
variable "vpc_cidr" {}

variable "public_subnet_az1_cidr" {}
variable "public_subnet_az2_cidr" {}

variable "private_app_subnet_az1_cidr" {}
variable "private_app_subnet_az2_cidr" {}

variable "private_data_subnet_az1_cidr" {}
variable "private_data_subnet_az2_cidr" {}


# Database (RDS)
variable "database_snapshot_identifier" {}
variable "database_instance_class" {}
variable "database_instance_identifier" {}
variable "multi_az_deployment" {}



# ECR
variable "repo_name" {
  description = "Base repo name (without env prefix). Example: rentzone-web"
  type        = string
}

variable "image_tag_mutability" {}
variable "scan_on_push" {}
variable "force_delete" {}
variable "enable_lifecycle_policy" {}
variable "lifecycle_keep_last_n" {}

variable "tags" {
  type    = map(string)
  default = {}
}

# ALB
variable "target_type" {}

# Route53
variable "domain_name" {}
variable "record_name" {}

# Secrets
variable "docker_env_secret_name" {
  description = "Name of the existing Secrets Manager secret that stores app env values, CONTAINER_IMAGE, certificate-arn, SSH_IP, etc."
  type        = string
}

# for the ecs.yml workflow that launches full infrastructure (including ecs.tf and asg.tf).


# ECS
#variable "cpu_architecture" {}
#variable "container_name" {}
#variable "ecs_service_max_capacity" {}
#variable "ecs_service_min_capacity" {}
#variable "ecs_desired_count" {}







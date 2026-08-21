locals {
  docker_env_secret_json = jsondecode(data.aws_secretsmanager_secret_version.docker_env_secret.secret_string)

  common_tags = {
    Name        = "${var.project_name}-${var.environment}-ecs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# create ecs cluster...use tagging format for dev env like in ecs role for the name
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-cluster"
    }
  )
}

# create cloudwatch log group
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/${var.project_name}-${var.environment}-td"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-log-group"
    }
  )
}

# non-secret environment variables and secrets to be injected
locals {
  non_secret_environment = [
    { name = "APP_ENV",        value = "production" },
    { name = "APP_DEBUG",      value = "false" },
    { name = "DB_CONNECTION",  value = "mysql" },
  ]

  # ECS secrets injection for environment variables
  # Uses the looked-up secret ARN, so ARN is NOT exposed in tfvars
  injected_secrets = [
    {
      name      = "APP_NAME"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:APP_NAME::"
    },
    {
      name      = "APP_URL"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:APP_URL::"
    },
    {
      name      = "DB_HOST"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:DB_HOST::"
    },
    {
      name      = "DB_PORT"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:DB_PORT::"
    },
    {
      name      = "DB_DATABASE"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:DB_DATABASE::"
    },
    {
      name      = "DB_USERNAME"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:DB_USERNAME::"
    },
    {
      name      = "DB_PASSWORD"
      valueFrom = "${data.aws_secretsmanager_secret.docker_env_secret.arn}:DB_PASSWORD::"
    }
  ]
}

# create task definition
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "${var.project_name}-${var.environment}-td"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = var.cpu_architecture
  }

  # create container definition
  # IMPORTANT:
  # image must be a resolved string at task-definition registration time
  # so we read CONTAINER_IMAGE from Secrets Manager in Terraform here
  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = local.docker_env_secret_json["CONTAINER_IMAGE"]
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]

      environment = local.non_secret_environment
      secrets     = local.injected_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-td"
    }
  )
}

# create ecs service
resource "aws_ecs_service" "ecs_service" {
  name                               = "${var.project_name}-${var.environment}-service"
  launch_type                        = "FARGATE"
  cluster                            = aws_ecs_cluster.ecs_cluster.id
  task_definition                    = aws_ecs_task_definition.ecs_task_definition.arn
  platform_version                   = "LATEST"
  desired_count                      = var.ecs_desired_count
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # task tagging configuration
  enable_ecs_managed_tags = false
  propagate_tags          = "SERVICE"

  # vpc and security group
  network_configuration {
    subnets          = [aws_subnet.private_app_subnet_az1.id, aws_subnet.private_app_subnet_az2.id]
    security_groups  = [aws_security_group.app_server_security_group.id]
    assign_public_ip = false
  }

  # load balancing
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = var.container_name
    container_port   = 80
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-service"
    }
  )
}
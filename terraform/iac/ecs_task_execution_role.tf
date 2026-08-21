
# create iam policy document. this policy allows the ecs service to assume a role
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#create secret data source to look up the existing secret in secrets manager by name. this allows us to reference the secret ARN without hardcoding it in tfvars.
data "aws_secretsmanager_secret" "docker_env_secret" {
  name = var.docker_env_secret_name
}

data "aws_secretsmanager_secret_version" "docker_env_secret" {
  secret_id = data.aws_secretsmanager_secret.docker_env_secret.id
}

# create iam policy document
data "aws_iam_policy_document" "ecs_task_execution_policy_document" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowSecretsManagerRead"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      data.aws_secretsmanager_secret.docker_env_secret.arn
    ]
  }
}

# create iam policy
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name   = "${var.project_name}-${var.environment}-ecs-task-execution-role-policy"
  policy = data.aws_iam_policy_document.ecs_task_execution_policy_document.json
}

# create an iam role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# attach ecs task execution policy to the iam role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}
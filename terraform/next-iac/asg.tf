# SNS topic for ECS CPU alerts
resource "aws_sns_topic" "ecs_cpu_alerts" {
  name = "${var.project_name}-${var.environment}-ecs-cpu-alerts"
}

# Email subscription for ECS CPU alerts
resource "aws_sns_topic_subscription" "ecs_cpu_email_alerts" {
  topic_arn = aws_sns_topic.ecs_cpu_alerts.arn
  protocol  = "email"
  endpoint  = local.docker_env_secret_json["SNS_EMAIL"]
}

# ECS service autoscaling configuration
resource "aws_appautoscaling_target" "ecs_asg" {
  max_capacity       = var.ecs_service_max_capacity
  min_capacity       = var.ecs_service_min_capacity
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "${var.project_name}-${var.environment}-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_asg.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 70
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
    disable_scale_in   = false
  }

  depends_on = [aws_appautoscaling_target.ecs_asg]
}

# CloudWatch alarm for high ECS CPU
resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-high-cpu"
  alarm_description   = "Triggers when ECS service average CPU utilization is above 70%."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_ecs_cluster.ecs_cluster.name
    ServiceName = aws_ecs_service.ecs_service.name
  }

  alarm_actions = [
    aws_sns_topic.ecs_cpu_alerts.arn
  ]
}
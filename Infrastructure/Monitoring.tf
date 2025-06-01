# Simple CloudWatch Dashboard for QueryGPT RAG Application
resource "aws_cloudwatch_dashboard" "querygpt_dashboard" {
  dashboard_name = "QueryGPT-Basic-Dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      # Basic title header
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# QueryGPT RAG Application"
        }
      },

      # LLM Instance CPU Utilization - Simple view
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "${aws_instance.llm_instance.id}"]
          ]
          region = "us-east-1"
          title  = "LLM Server CPU"
          period = 300
          stat   = "Average"
        }
      },

      # Vector DB - Memory (most critical metric)
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${aws_ecs_cluster.qdrant_cluster.name}", "ServiceName", "qdrant-service"]
          ]
          region = "us-east-1"
          title  = "Vector DB Memory"
          period = 300
          stat   = "Average"
        }
      },

      # Frontend & LLM Service - Combined Requests
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 24
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}", { label: "LLM Requests" }],
            ["AWS/Amplify", "Requests", "App", "${aws_amplify_app.frontend.id}", { label: "Frontend Requests" }]
          ]
          region = "us-east-1"
          title  = "System Traffic"
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

# Define Single Critical CloudWatch Alarm

# Vector DB High Memory Alarm (most critical for vector database performance)
resource "aws_cloudwatch_metric_alarm" "qdrant_high_memory" {
  alarm_name          = "VectorDBHighMemory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Alarm when Vector DB memory exceeds 85%"
  alarm_actions       = [aws_sns_topic.monitoring_alerts.arn]
  dimensions = {
    ClusterName = aws_ecs_cluster.qdrant_cluster.name
    ServiceName = "qdrant-service"
  }
}

# Simplified SNS Topic for Critical Alerts
resource "aws_sns_topic" "monitoring_alerts" {
  name = "querygpt-critical-alerts"
}

# Simple Email Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Define the alert_email variable
variable "alert_email" {
  description = "Email address to receive monitoring alerts"
  type        = string
  default     = "alerts@example.com"  # Replace with your actual email
}

# Minimal CloudWatch Agent Configuration
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name  = "/QueryGPT/CloudWatch/Config"
  type  = "String"
  value = jsonencode({
    metrics = {
      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        },
        disk = {
          measurement = ["used_percent"],
          resources = ["/"]
        }
      }
    },
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path = "/var/log/user-data.log",
              log_group_name = "/aws/ec2/querygpt-llm",
              log_stream_name = "{instance_id}"
            }
          ]
        }
      }
    }
  })
}
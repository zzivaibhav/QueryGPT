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

      # LLM Instance Memory Utilization (from CloudWatch Agent)
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["CWAgent", "mem_used_percent", "InstanceId", "${aws_instance.llm_instance.id}"]
          ],
          region = "us-east-1",
          title  = "LLM Server Memory Usage"
          period = 300
          stat   = "Average"
        }
      },
      
      # Disk Usage for LLM instance (important for model storage)
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["CWAgent", "disk_used_percent", "InstanceId", "${aws_instance.llm_instance.id}", "path", "/"]
          ],
          region = "us-east-1",
          title  = "LLM Server Disk Usage"
          period = 300
          stat   = "Average"
          yAxis  = {
            left: {
              min: 0,
              max: 100
            }
          }
        }
      },

      # Network In/Out for LLM Server (important for request handling)
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", "${aws_instance.llm_instance.id}", { label: "Network In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", "${aws_instance.llm_instance.id}", { label: "Network Out" }]
          ]
          region = "us-east-1"
          title  = "LLM Server Network Traffic"
          period = 300
          stat   = "Sum"
        }
      },
      
      # EFS Metrics for Vector DB Storage
      {
        type   = "metric"
        x      = 12
        y      = 13
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/EFS", "StorageBytes", "FileSystemId", "${aws_efs_file_system.qdrant_efs.id}", "StorageClass", "Total"],
            ["AWS/EFS", "ThroughputMB", "FileSystemId", "${aws_efs_file_system.qdrant_efs.id}"],
            ["AWS/EFS", "IOLimit%", "FileSystemId", "${aws_efs_file_system.qdrant_efs.id}"]
          ]
          region = "us-east-1"
          title  = "Qdrant EFS Storage Metrics"
          period = 300
          stat   = "Average"
        }
      },

      # Load Balancer Metrics
      {
        type   = "metric"
        x      = 0
        y      = 19
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}"],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}"]
          ]
          region = "us-east-1"
          title  = "LLM Load Balancer Metrics"
          period = 60
          stat   = "Average"
        }
      },

      # HTTP Error Codes (important for monitoring service health)
      {
        type   = "metric"
        x      = 12
        y      = 19
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_ELB_4XX_Count", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${aws_lb.llm_lb.arn_suffix}"]
          ]
          region = "us-east-1"
          title  = "HTTP Error Codes"
          period = 60
          stat   = "Sum"
        }
      },
      
      # Qdrant ECS Service Metrics
      {
        type   = "metric"
        x      = 0
        y      = 25
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "${aws_ecs_cluster.qdrant_cluster.name}", "ServiceName", "qdrant-service"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "${aws_ecs_cluster.qdrant_cluster.name}", "ServiceName", "qdrant-service"]
          ]
          region = "us-east-1"
          title  = "Qdrant ECS Service Performance"
          period = 300
          stat   = "Average"
        }
      },
      
      # Amplify Frontend Metrics
      {
        type   = "metric"
        x      = 12
        y      = 25
        width  = 12
        height = 6
        properties = {
          view    = "timeSeries"
          metrics = [
            ["AWS/Amplify", "Requests", "App", "${aws_amplify_app.frontend.id}"],
            ["AWS/Amplify", "BytesDownloaded", "App", "${aws_amplify_app.frontend.id}"]
          ]
          region = "us-east-1"
          title  = "Frontend Traffic"
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

 
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
  default     = "vaibhavpatel9196@gmail.com"  # Replace with your actual email
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
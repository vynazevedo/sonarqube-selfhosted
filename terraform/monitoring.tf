resource "aws_cloudwatch_metric_alarm" "auto_recover" {
  alarm_name          = "${var.name}-system-check-failed"
  alarm_description   = "Recovers the instance automatically on host-level failure"
  namespace           = "AWS/EC2"
  metric_name         = "StatusCheckFailed_System"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 2
  period              = 60
  statistic           = "Maximum"
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current.region}:ec2:recover"]
  tags                = var.tags

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.name}-cpu-high"
  alarm_description   = "Sustained high CPU on the SonarQube instance"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 90
  evaluation_periods  = 3
  period              = 300
  statistic           = "Average"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = var.tags

  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "disk" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.name}-data-disk-usage"
  alarm_description   = "Data volume usage above 80 percent"
  namespace           = "CWAgent"
  metric_name         = "disk_used_percent"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = var.tags

  dimensions = {
    InstanceId = aws_instance.this.id
    path       = "/var/lib/docker"
    fstype     = "xfs"
  }
}

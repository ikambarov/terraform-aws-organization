output "config_aggregator_arn" {
  description = "AWS Config aggregator ARN in the security account."
  value       = aws_config_configuration_aggregator.security.arn
}

output "workload_dev_config_recorder_name" {
  description = "AWS Config recorder name in workload-dev."
  value       = aws_config_configuration_recorder.workload_dev.name
}

output "workload_prod_config_recorder_name" {
  description = "AWS Config recorder name in workload-prod."
  value       = aws_config_configuration_recorder.workload_prod.name
}

output "guardduty_detector_ids" {
  description = "GuardDuty detector IDs."
  value = {
    security      = aws_guardduty_detector.security.id
    workload_dev  = aws_guardduty_detector.workload_dev.id
    workload_prod = aws_guardduty_detector.workload_prod.id
  }
}

output "securityhub_foundational_best_practices_subscription_ids" {
  description = "Security Hub AWS Foundational Security Best Practices subscription IDs."
  value = {
    security      = aws_securityhub_standards_subscription.security_foundational_best_practices.id
    workload_dev  = aws_securityhub_standards_subscription.workload_dev_foundational_best_practices.id
    workload_prod = aws_securityhub_standards_subscription.workload_prod_foundational_best_practices.id
  }
}

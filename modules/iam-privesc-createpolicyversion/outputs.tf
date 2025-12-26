output "entry_role_name" {
  description = "Name of the entry role for the CreatePolicyVersion lab"
  value       = aws_iam_role.entry_role.name
}

output "entry_role_arn" {
  description = "ARN of the entry role for the CreatePolicyVersion lab"
  value       = aws_iam_role.entry_role.arn
}

output "vulnerable_policy_arn" {
  description = "ARN of the vulnerable managed policy"
  value       = aws_iam_policy.vulnerable_policy.arn
}

output "vulnerable_policy_name" {
  description = "Name of the vulnerable managed policy"
  value       = aws_iam_policy.vulnerable_policy.name
}

output "escalated_permissions_policy_arn" {
  description = "ARN of the policy showing what permissions should be gained after escalation"
  value       = aws_iam_policy.escalated_permissions.arn
}

output "flag_role_name" {
  description = "Name of the IAM role containing the flag for this lab"
  value       = aws_iam_role.flag_holder.name
}

output "entry_role_name" {
  description = "Name of the entry IAM role for the AttachRolePolicy lab"
  value       = aws_iam_role.entry_role.name
}

output "entry_role_arn" {
  description = "ARN of the entry IAM role for the AttachRolePolicy lab"
  value       = aws_iam_role.entry_role.arn
}

output "target_role_arn" {
  description = "ARN of the target role for policy attachment"
  value       = aws_iam_role.target_role.arn
}

output "target_role_name" {
  description = "Name of the target role"
  value       = aws_iam_role.target_role.name
}

output "flag_access_policy_arn" {
  description = "ARN of the policy that grants flag access"
  value       = aws_iam_policy.flag_access_policy.arn
}

output "flag_role_name" {
  description = "Name of the IAM role containing the flag for this lab"
  value       = aws_iam_role.flag_holder.name
}

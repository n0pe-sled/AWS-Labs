output "entry_role_name" {
  description = "Name of the entry IAM role for the PutUserPolicy lab"
  value       = aws_iam_role.entry_role.name
}

output "entry_role_arn" {
  description = "ARN of the entry IAM role for the PutUserPolicy lab"
  value       = aws_iam_role.entry_role.arn
}

output "flag_role_name" {
  description = "Name of the IAM role containing the flag for this lab"
  value       = aws_iam_role.flag_holder.name
}

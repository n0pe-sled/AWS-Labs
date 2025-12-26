output "entry_role_name" {
  description = "Name of the entry IAM role for the CreateCredentials lab"
  value       = aws_iam_role.entry_role.name
}

output "entry_role_arn" {
  description = "ARN of the entry IAM role for the CreateCredentials lab"
  value       = aws_iam_role.entry_role.arn
}

output "privileged_user_name" {
  description = "Name of the privileged target user"
  value       = aws_iam_user.privileged_user.name
}

output "privileged_user_arn" {
  description = "ARN of the privileged target user"
  value       = aws_iam_user.privileged_user.arn
}

output "flag_role_name" {
  description = "Name of the IAM role containing the flag for this lab"
  value       = aws_iam_role.flag_holder.name
}

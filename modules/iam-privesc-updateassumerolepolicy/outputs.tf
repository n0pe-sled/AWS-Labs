output "entry_role_name" {
  description = "Name of the entry IAM role"
  value       = aws_iam_role.entry_role.name
}

output "entry_role_arn" {
  description = "ARN of the entry IAM role"
  value       = aws_iam_role.entry_role.arn
}

output "privileged_role_arn" {
  description = "ARN of the privileged role that can be assumed after updating trust policy"
  value       = aws_iam_role.privileged_role.arn
}

output "privileged_role_name" {
  description = "Name of the privileged role that can be assumed after updating trust policy"
  value       = aws_iam_role.privileged_role.name
}

output "flag_role_name" {
  description = "Name of the IAM role containing the flag for this lab"
  value       = aws_iam_role.flag_holder.name
}

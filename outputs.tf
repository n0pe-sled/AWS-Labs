# CreatePolicyVersion lab outputs
output "createpolicyversion_entry_role_arn" {
  description = "ARN of the entry role for the CreatePolicyVersion lab"
  value       = var.enable_createpolicyversion_lab ? module.iam_privesc_createpolicyversion[0].entry_role_arn : null
}

output "createpolicyversion_entry_role_name" {
  description = "Name of the entry role for the CreatePolicyVersion lab"
  value       = var.enable_createpolicyversion_lab ? module.iam_privesc_createpolicyversion[0].entry_role_name : null
}

output "createpolicyversion_policy_arn" {
  description = "ARN of the managed policy attached to the entry role"
  value       = var.enable_createpolicyversion_lab ? module.iam_privesc_createpolicyversion[0].vulnerable_policy_arn : null
}

output "createpolicyversion_flag_role_name" {
  description = "Name of the IAM role containing the flag for CreatePolicyVersion lab"
  value       = var.enable_createpolicyversion_lab ? module.iam_privesc_createpolicyversion[0].flag_role_name : null
}

# AssumeRole lab outputs
output "assumerole_entry_role_arn" {
  description = "ARN of the entry role for the AssumeRole lab"
  value       = var.enable_assumerole_lab ? module.iam_privesc_assumerole[0].entry_role_arn : null
}

output "assumerole_entry_role_name" {
  description = "Name of the entry role for the AssumeRole lab"
  value       = var.enable_assumerole_lab ? module.iam_privesc_assumerole[0].entry_role_name : null
}

output "assumerole_privileged_role_arn" {
  description = "ARN of the privileged role for the AssumeRole lab"
  value       = var.enable_assumerole_lab ? module.iam_privesc_assumerole[0].privileged_role_arn : null
}

output "assumerole_flag_role_name" {
  description = "Name of the IAM role containing the flag for AssumeRole lab"
  value       = var.enable_assumerole_lab ? module.iam_privesc_assumerole[0].flag_role_name : null
}

# PutUserPolicy lab outputs
output "putuserpolicy_entry_role_arn" {
  description = "ARN of the entry role for the PutUserPolicy lab"
  value       = var.enable_putuserpolicy_lab ? module.iam_privesc_putuserpolicy[0].entry_role_arn : null
}

output "putuserpolicy_entry_role_name" {
  description = "Name of the entry role for the PutUserPolicy lab"
  value       = var.enable_putuserpolicy_lab ? module.iam_privesc_putuserpolicy[0].entry_role_name : null
}

output "putuserpolicy_flag_role_name" {
  description = "Name of the IAM role containing the flag for PutUserPolicy lab"
  value       = var.enable_putuserpolicy_lab ? module.iam_privesc_putuserpolicy[0].flag_role_name : null
}

# AttachRolePolicy lab outputs
output "attachrolepolicy_entry_role_arn" {
  description = "ARN of the entry role for the AttachRolePolicy lab"
  value       = var.enable_attachrolepolicy_lab ? module.iam_privesc_attachrolepolicy[0].entry_role_arn : null
}

output "attachrolepolicy_entry_role_name" {
  description = "Name of the entry role for the AttachRolePolicy lab"
  value       = var.enable_attachrolepolicy_lab ? module.iam_privesc_attachrolepolicy[0].entry_role_name : null
}

output "attachrolepolicy_target_role_arn" {
  description = "ARN of the target role for the AttachRolePolicy lab"
  value       = var.enable_attachrolepolicy_lab ? module.iam_privesc_attachrolepolicy[0].target_role_arn : null
}

output "attachrolepolicy_flag_policy_arn" {
  description = "ARN of the flag access policy for the AttachRolePolicy lab"
  value       = var.enable_attachrolepolicy_lab ? module.iam_privesc_attachrolepolicy[0].flag_access_policy_arn : null
}

output "attachrolepolicy_flag_role_name" {
  description = "Name of the IAM role containing the flag for AttachRolePolicy lab"
  value       = var.enable_attachrolepolicy_lab ? module.iam_privesc_attachrolepolicy[0].flag_role_name : null
}

# CreateCredentials lab outputs
output "createcredentials_entry_role_arn" {
  description = "ARN of the entry role for the CreateCredentials lab"
  value       = var.enable_createcredentials_lab ? module.iam_privesc_createcredentials[0].entry_role_arn : null
}

output "createcredentials_entry_role_name" {
  description = "Name of the entry role for the CreateCredentials lab"
  value       = var.enable_createcredentials_lab ? module.iam_privesc_createcredentials[0].entry_role_name : null
}

output "createcredentials_privileged_user_name" {
  description = "Name of the privileged target user for the CreateCredentials lab"
  value       = var.enable_createcredentials_lab ? module.iam_privesc_createcredentials[0].privileged_user_name : null
}

output "createcredentials_privileged_user_arn" {
  description = "ARN of the privileged target user for the CreateCredentials lab"
  value       = var.enable_createcredentials_lab ? module.iam_privesc_createcredentials[0].privileged_user_arn : null
}

output "createcredentials_flag_role_name" {
  description = "Name of the IAM role containing the flag for CreateCredentials lab"
  value       = var.enable_createcredentials_lab ? module.iam_privesc_createcredentials[0].flag_role_name : null
}

# UpdateAssumeRolePolicy lab outputs
output "updateassumerolepolicy_entry_role_arn" {
  description = "ARN of the entry role for the UpdateAssumeRolePolicy lab"
  value       = var.enable_updateassumerolepolicy_lab ? module.iam_privesc_updateassumerolepolicy[0].entry_role_arn : null
}

output "updateassumerolepolicy_entry_role_name" {
  description = "Name of the entry role for the UpdateAssumeRolePolicy lab"
  value       = var.enable_updateassumerolepolicy_lab ? module.iam_privesc_updateassumerolepolicy[0].entry_role_name : null
}

output "updateassumerolepolicy_privileged_role_arn" {
  description = "ARN of the privileged role for the UpdateAssumeRolePolicy lab"
  value       = var.enable_updateassumerolepolicy_lab ? module.iam_privesc_updateassumerolepolicy[0].privileged_role_arn : null
}

output "updateassumerolepolicy_privileged_role_name" {
  description = "Name of the privileged role for the UpdateAssumeRolePolicy lab"
  value       = var.enable_updateassumerolepolicy_lab ? module.iam_privesc_updateassumerolepolicy[0].privileged_role_name : null
}

output "updateassumerolepolicy_flag_role_name" {
  description = "Name of the IAM role containing the flag for UpdateAssumeRolePolicy lab"
  value       = var.enable_updateassumerolepolicy_lab ? module.iam_privesc_updateassumerolepolicy[0].flag_role_name : null
}

# Add more module outputs as you create additional labs

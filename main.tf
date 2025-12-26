# IAM Privilege Escalation: CreatePolicyVersion
module "iam_privesc_createpolicyversion" {
  count  = var.enable_createpolicyversion_lab ? 1 : 0
  source = "./modules/iam-privesc-createpolicyversion"

  lab_prefix = var.lab_prefix
  flag_value = var.flag_createpolicyversion
}

# IAM Privilege Escalation: AssumeRole
module "iam_privesc_assumerole" {
  count  = var.enable_assumerole_lab ? 1 : 0
  source = "./modules/iam-privesc-assumerole"

  lab_prefix = var.lab_prefix
  flag_value = var.flag_assumerole
}

# IAM Privilege Escalation: PutUserPolicy
module "iam_privesc_putuserpolicy" {
  count  = var.enable_putuserpolicy_lab ? 1 : 0
  source = "./modules/iam-privesc-putuserpolicy"

  lab_prefix = var.lab_prefix
  flag_value = var.flag_putuserpolicy
}

# IAM Privilege Escalation: AttachRolePolicy
module "iam_privesc_attachrolepolicy" {
  count  = var.enable_attachrolepolicy_lab ? 1 : 0
  source = "./modules/iam-privesc-attachrolepolicy"

  lab_prefix = var.lab_prefix
  flag_value = var.flag_attachrolepolicy
}

# IAM Privilege Escalation: CreateAccessKey & CreateLoginProfile
module "iam_privesc_createcredentials" {
  count  = var.enable_createcredentials_lab ? 1 : 0
  source = "./modules/iam-privesc-createcredentials"

  lab_prefix = var.lab_prefix
  flag_value = var.flag_createcredentials
}

# IAM Privilege Escalation: UpdateAssumeRolePolicy
module "iam_privesc_updateassumerolepolicy" {
  count  = var.enable_updateassumerolepolicy_lab ? 1 : 0
  source = "./modules/iam-privesc-updateassumerolepolicy"

  lab_prefix = var.lab_prefix
  flag_value = var.flag_updateassumerolepolicy
}

# Add more lab modules here as they are created
# module "iam_privesc_passrole" {
#   count  = var.enable_passrole_lab ? 1 : 0
#   source = "./modules/iam-privesc-passrole"
#
#   lab_prefix      = var.lab_prefix
#   flag_role_arn   = module.shared.flag_role_arn
#   flag_role_name  = module.shared.flag_role_name
# }

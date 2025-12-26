variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "lab"
}

variable "lab_prefix" {
  description = "Prefix for all lab resources"
  type        = string
  default     = "aws-lab"
}

# Module enablement flags
variable "enable_createpolicyversion_lab" {
  description = "Enable the CreatePolicyVersion privilege escalation lab"
  type        = bool
  default     = true
}

variable "enable_assumerole_lab" {
  description = "Enable the AssumeRole privilege escalation lab"
  type        = bool
  default     = false
}

variable "enable_putuserpolicy_lab" {
  description = "Enable the PutUserPolicy privilege escalation lab"
  type        = bool
  default     = false
}

variable "enable_attachrolepolicy_lab" {
  description = "Enable the AttachRolePolicy privilege escalation lab"
  type        = bool
  default     = false
}

variable "enable_createcredentials_lab" {
  description = "Enable the CreateAccessKey & CreateLoginProfile privilege escalation lab"
  type        = bool
  default     = false
}

variable "enable_updateassumerolepolicy_lab" {
  description = "Enable the UpdateAssumeRolePolicy privilege escalation lab"
  type        = bool
  default     = false
}

# Add more module flags as you create additional labs
# variable "enable_passrole_lab" {
#   description = "Enable the PassRole privilege escalation lab"
#   type        = bool
#   default     = false
# }

# Flag configuration - Each lab has a unique flag
variable "flag_createpolicyversion" {
  description = "Flag value for CreatePolicyVersion lab"
  type        = string
  default     = "SPECTER:cr34t3_p0l1cy_v3rs10n_pwn3d"
  sensitive   = true
}

variable "flag_assumerole" {
  description = "Flag value for AssumeRole lab"
  type        = string
  default     = "SPECTER:4ssum3_r0l3_trust_p0l1cy_pwn3d"
  sensitive   = true
}

variable "flag_putuserpolicy" {
  description = "Flag value for PutUserPolicy lab"
  type        = string
  default     = "SPECTER:put_us3r_p0l1cy_3sc4l4t10n"
  sensitive   = true
}

variable "flag_attachrolepolicy" {
  description = "Flag value for AttachRolePolicy lab"
  type        = string
  default     = "SPECTER:4tt4ch_r0l3_p0l1cy_3xpl01t"
  sensitive   = true
}

variable "flag_createcredentials" {
  description = "Flag value for CreateCredentials lab"
  type        = string
  default     = "SPECTER:cr34t3_cr3d3nt14ls_h4ck3d"
  sensitive   = true
}

variable "flag_updateassumerolepolicy" {
  description = "Flag value for UpdateAssumeRolePolicy lab"
  type        = string
  default     = "SPECTER:upd4t3_trust_p0l1cy_pwn3d"
  sensitive   = true
}

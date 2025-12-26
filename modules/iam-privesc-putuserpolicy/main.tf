# Permission boundary to limit escalation scope
resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.lab_prefix}-putuserpolicy-boundary"
  description = "Permission boundary to limit privilege escalation scope for PutUserPolicy lab"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowIAMReadOperations"
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEscalationVector"
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy"
        ]
        Resource = "arn:aws:iam::*:role/*"
      },
      {
        Sid    = "AllowSTSOperations"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyAllOtherServices"
        Effect = "Deny"
        NotAction = [
          "iam:Get*",
          "iam:List*",
          "iam:PutRolePolicy",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-putuserpolicy-boundary"
    LabExercise = "PutUserPolicy"
  }
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# Entry role with limited permissions but can modify its own inline policies
resource "aws_iam_role" "entry_role" {
  name                 = "${var.lab_prefix}-putuserpolicy-entry"
  description          = "Entry role with limited permissions for PutUserPolicy lab"
  path                 = "/"
  permissions_boundary = aws_iam_policy.permission_boundary.arn

  # Trust policy allows assumption by account root
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-putuserpolicy-entry"
    LabExercise = "PutUserPolicy"
  }
}

# Initial inline policy with limited permissions including the escalation vector
resource "aws_iam_role_policy" "initial_policy" {
  name = "${var.lab_prefix}-putuserpolicy-initial"
  role = aws_iam_role.entry_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeSelf"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_prefix}-putuserpolicy-entry"
      },
      {
        Sid    = "EscalationVector"
        Effect = "Allow"
        Action = [
          "iam:PutRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_prefix}-putuserpolicy-entry"
      }
    ]
  })
}

# IAM role containing the flag as a tag for this lab
resource "aws_iam_role" "flag_holder" {
  name        = "${var.lab_prefix}-putuserpolicy-flag-holder"
  description = "IAM role that contains the PutUserPolicy lab flag as a tag"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-putuserpolicy-flag-holder"
    flag        = var.flag_value
    lab         = "PutUserPolicy"
    description = "Congratulations - You have successfully escalated privileges in the Specter AWS Lab"
  }
}

# Optional: IAM policy to demonstrate what the user SHOULD be able to access after escalation
# This is for documentation/testing purposes
resource "aws_iam_policy" "escalated_permissions" {
  name        = "${var.lab_prefix}-putuserpolicy-escalated"
  description = "Permissions the user should gain after successful privilege escalation"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadFlagFromRoleTags"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListRoleTags",
          "iam:ListRoles"
        ]
        Resource = aws_iam_role.flag_holder.arn
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-putuserpolicy-escalated"
    LabExercise = "PutUserPolicy"
    Purpose     = "Documentation"
  }
}

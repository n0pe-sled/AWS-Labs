# Customer-managed policy that the user can modify
resource "aws_iam_policy" "vulnerable_policy" {
  name        = "${var.lab_prefix}-createpolicyversion-policy"
  description = "Vulnerable policy for CreatePolicyVersion privilege escalation lab"
  path        = "/"

  # Initial limited permissions - user can only describe themselves and create policy versions
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeSelf"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListAttachedUserPolicies",
          "iam:ListUserPolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions"
        ]
        Resource = "*"
      },
      {
        Sid    = "EscalationVector"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicyVersion"
        ]
        Resource = "arn:aws:iam::*:policy/${var.lab_prefix}-createpolicyversion-policy"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-createpolicyversion-policy"
    LabExercise = "CreatePolicyVersion"
  }
}

# Permission boundary to limit escalation scope
resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.lab_prefix}-createpolicyversion-boundary"
  description = "Permission boundary to limit privilege escalation scope for CreatePolicyVersion lab"
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
          "iam:CreatePolicyVersion"
        ]
        Resource = "arn:aws:iam::*:policy/${var.lab_prefix}-createpolicyversion-policy"
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
          "iam:CreatePolicyVersion",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-createpolicyversion-boundary"
    LabExercise = "CreatePolicyVersion"
  }
}

# IAM role for lab entry point (replaces user-based access)
resource "aws_iam_role" "entry_role" {
  name                 = "${var.lab_prefix}-createpolicyversion-entry"
  description          = "Entry role for CreatePolicyVersion privilege escalation lab"
  path                 = "/"
  permissions_boundary = aws_iam_policy.permission_boundary.arn

  # Trust policy - allows assumption by any principal in the AWS account
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
    Name        = "${var.lab_prefix}-createpolicyversion-entry"
    LabExercise = "CreatePolicyVersion"
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Attach the vulnerable policy to the entry role
resource "aws_iam_role_policy_attachment" "entry_role_attachment" {
  role       = aws_iam_role.entry_role.name
  policy_arn = aws_iam_policy.vulnerable_policy.arn
}

# IAM role containing the flag as a tag for this lab
resource "aws_iam_role" "flag_holder" {
  name        = "${var.lab_prefix}-createpolicyversion-flag-holder"
  description = "IAM role that contains the CreatePolicyVersion lab flag as a tag"

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
    Name        = "${var.lab_prefix}-createpolicyversion-flag-holder"
    flag        = var.flag_value
    lab         = "CreatePolicyVersion"
    description = "Congratulations - You have successfully escalated privileges in the Specter AWS Lab"
  }
}

# Optional: IAM policy to demonstrate what the user SHOULD be able to access after escalation
# This is for documentation/testing purposes
resource "aws_iam_policy" "escalated_permissions" {
  name        = "${var.lab_prefix}-createpolicyversion-escalated"
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
          "iam:ListRoleTags"
        ]
        Resource = aws_iam_role.flag_holder.arn
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-createpolicyversion-escalated"
    LabExercise = "CreatePolicyVersion"
    Purpose     = "Documentation"
  }
}

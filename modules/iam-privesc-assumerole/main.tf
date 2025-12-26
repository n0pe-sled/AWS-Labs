# Permission boundary for the privileged role to limit what it can do after assumption
resource "aws_iam_policy" "role_permission_boundary" {
  name        = "${var.lab_prefix}-assumerole-role-boundary"
  description = "Permission boundary for privileged role in AssumeRole lab"
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
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-assumerole-role-boundary"
    LabExercise = "AssumeRole"
  }
}

# Permission boundary for the entry role
resource "aws_iam_policy" "entry_role_permission_boundary" {
  name        = "${var.lab_prefix}-assumerole-entry-boundary"
  description = "Permission boundary for entry role in AssumeRole lab"
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
        Sid    = "AllowAssumeRole"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
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
          "sts:AssumeRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-assumerole-entry-boundary"
    LabExercise = "AssumeRole"
  }
}

# Target role with overly permissive trust policy
# The vulnerability: Trust policy allows the root account, meaning ANY principal in the account can assume it
resource "aws_iam_role" "privileged_role" {
  name                 = "${var.lab_prefix}-assumerole-privileged"
  description          = "Privileged role with overly permissive trust policy for AssumeRole lab"
  permissions_boundary = aws_iam_policy.role_permission_boundary.arn

  # VULNERABLE: Trusts the entire AWS account root, not specific principals
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
    Name        = "${var.lab_prefix}-assumerole-privileged"
    LabExercise = "AssumeRole"
  }
}

# Attach policy to the privileged role that grants access to read the flag
resource "aws_iam_role_policy" "privileged_policy" {
  name = "${var.lab_prefix}-assumerole-flag-access"
  role = aws_iam_role.privileged_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOwnRoleDetails"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListRoles"
        ]
        Resource = [
          aws_iam_role.privileged_role.arn,
          aws_iam_role.flag_holder.arn
        ]
      },
      {
        Sid    = "ReadFlagFromRoleTags"
        Effect = "Allow"
        Action = [
          "iam:ListRoleTags"
        ]
        Resource = aws_iam_role.flag_holder.arn
      }
    ]
  })
}

# Entry role with limited permissions - can only assume roles
resource "aws_iam_role" "entry_role" {
  name                 = "${var.lab_prefix}-assumerole-entry"
  description          = "Entry role with limited permissions for AssumeRole lab"
  permissions_boundary = aws_iam_policy.entry_role_permission_boundary.arn

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
    Name        = "${var.lab_prefix}-assumerole-entry"
    LabExercise = "AssumeRole"
  }
}

# Policy that allows the entry role to assume any role (or discover roles)
resource "aws_iam_role_policy" "entry_role_policy" {
  name = "${var.lab_prefix}-assumerole-entry-policy"
  role = aws_iam_role.entry_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeSelf"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_prefix}-assumerole-entry"
      },
      {
        Sid    = "ListRoles"
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:GetRole"
        ]
        Resource = "*"
      },
      {
        Sid    = "AssumeRoles"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# IAM role containing the flag as a tag for this lab
resource "aws_iam_role" "flag_holder" {
  name        = "${var.lab_prefix}-assumerole-flag-holder"
  description = "IAM role that contains the AssumeRole lab flag as a tag"

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
    Name        = "${var.lab_prefix}-assumerole-flag-holder"
    flag        = var.flag_value
    lab         = "AssumeRole"
    description = "Congratulations - You have successfully escalated privileges in the Specter AWS Lab"
  }
}

# Optional: IAM policy to demonstrate what permissions the privileged role has
# This is for documentation/testing purposes
resource "aws_iam_policy" "escalated_permissions" {
  name        = "${var.lab_prefix}-assumerole-escalated"
  description = "Permissions the user should gain after successfully assuming the privileged role"
  path        = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadOwnRoleDetails"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListRoles"
        ]
        Resource = [
          aws_iam_role.privileged_role.arn,
          aws_iam_role.flag_holder.arn
        ]
      },
      {
        Sid    = "ReadFlagFromRoleTags"
        Effect = "Allow"
        Action = [
          "iam:ListRoleTags"
        ]
        Resource = aws_iam_role.flag_holder.arn
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-assumerole-escalated"
    LabExercise = "AssumeRole"
    Purpose     = "Documentation"
  }
}

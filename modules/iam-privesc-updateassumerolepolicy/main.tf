# Data source to get current account ID
data "aws_caller_identity" "current" {}

# Permission boundary for the privileged role to limit what it can do after assumption
resource "aws_iam_policy" "role_permission_boundary" {
  name        = "${var.lab_prefix}-updateassumerolepolicy-role-boundary"
  description = "Permission boundary for privileged role in UpdateAssumeRolePolicy lab"
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
    Name        = "${var.lab_prefix}-updateassumerolepolicy-role-boundary"
    LabExercise = "UpdateAssumeRolePolicy"
  }
}

# Permission boundary for the entry role
resource "aws_iam_policy" "entry_role_permission_boundary" {
  name        = "${var.lab_prefix}-updateassumerolepolicy-entry-boundary"
  description = "Permission boundary for entry role in UpdateAssumeRolePolicy lab"
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
          "iam:UpdateAssumeRolePolicy"
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
          "iam:UpdateAssumeRolePolicy",
          "sts:AssumeRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-updateassumerolepolicy-entry-boundary"
    LabExercise = "UpdateAssumeRolePolicy"
  }
}

# Privileged role with access to the flag
resource "aws_iam_role" "privileged_role" {
  name                 = "${var.lab_prefix}-updateassumerolepolicy-privileged"
  description          = "Privileged role with access to the flag - trust policy can be modified"
  permissions_boundary = aws_iam_policy.role_permission_boundary.arn

  # Initial trust policy that doesn't allow the vulnerable user to assume the role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Principal = {
        AWS = "*"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.lab_prefix}-updateassumerolepolicy-privileged"
    LabExercise = "UpdateAssumeRolePolicy"
    Purpose     = "PrivilegedRole"
  }
}

# Policy granting the privileged role access to read the flag
resource "aws_iam_role_policy" "privileged_role_policy" {
  name = "${var.lab_prefix}-updateassumerolepolicy-privileged-policy"
  role = aws_iam_role.privileged_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadFlagFromRoleTags"
      Effect = "Allow"
      Action = [
        "iam:GetRole",
        "iam:ListRoleTags",
        "iam:ListRoles"
      ]
      Resource = aws_iam_role.flag_holder.arn
    }]
  })
}

# Entry role with permission to update the assume role policy
resource "aws_iam_role" "entry_role" {
  name                 = "${var.lab_prefix}-updateassumerolepolicy-entry"
  description          = "Entry role with limited permissions for UpdateAssumeRolePolicy lab"
  path                 = "/"
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
    Name        = "${var.lab_prefix}-updateassumerolepolicy-entry"
    LabExercise = "UpdateAssumeRolePolicy"
    Purpose     = "EntryRole"
  }
}

# Entry role policy allowing assume role policy modification
resource "aws_iam_role_policy" "entry_role_policy" {
  name = "${var.lab_prefix}-updateassumerolepolicy-entry-policy"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_prefix}-updateassumerolepolicy-entry"
      },
      {
        Sid    = "DiscoverRoles"
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyAccessToFlag"
        Effect = "Deny"
        Action = [
          "iam:GetRole",
          "iam:ListRoleTags",
          "iam:ListRoles"
        ]
        Resource = aws_iam_role.flag_holder.arn
      },
      {
        Sid    = "EscalationVectorUpdateAssumeRolePolicy"
        Effect = "Allow"
        Action = [
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = aws_iam_role.privileged_role.arn
      },
      {
        Sid    = "AssumeModifiedRole"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = aws_iam_role.privileged_role.arn
      }
    ]
  })
}

# IAM role containing the flag as a tag for this lab
resource "aws_iam_role" "flag_holder" {
  name        = "${var.lab_prefix}-updateassumerolepolicy-flag-holder"
  description = "IAM role that contains the UpdateAssumeRolePolicy lab flag as a tag"

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
    Name        = "${var.lab_prefix}-updateassumerolepolicy-flag-holder"
    flag        = var.flag_value
    lab         = "UpdateAssumeRolePolicy"
    description = "Congratulations - You have successfully escalated privileges in the Specter AWS Lab"
  }
}

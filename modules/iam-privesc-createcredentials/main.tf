# Permission boundary for the privileged user to limit what they can do
resource "aws_iam_policy" "privileged_user_boundary" {
  name        = "${var.lab_prefix}-createcredentials-privileged-boundary"
  description = "Permission boundary for privileged user in CreateCredentials lab"
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
    Name        = "${var.lab_prefix}-createcredentials-privileged-boundary"
    LabExercise = "CreateCredentials"
  }
}

# Permission boundary for the entry role
resource "aws_iam_policy" "entry_role_boundary" {
  name        = "${var.lab_prefix}-createcredentials-entry-boundary"
  description = "Permission boundary for entry role in CreateCredentials lab"
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
          "iam:CreateAccessKey",
          "iam:CreateLoginProfile"
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
          "iam:CreateAccessKey",
          "iam:CreateLoginProfile",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-createcredentials-entry-boundary"
    LabExercise = "CreateCredentials"
  }
}

# Privileged target user with access to the flag but no active credentials
resource "aws_iam_user" "privileged_user" {
  name                 = "${var.lab_prefix}-createcredentials-privileged"
  path                 = "/"
  permissions_boundary = aws_iam_policy.privileged_user_boundary.arn

  tags = {
    Name        = "${var.lab_prefix}-createcredentials-privileged"
    LabExercise = "CreateCredentials"
    Purpose     = "TargetUser"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "bash ${path.module}/../../scripts/CreateCredentials-Cleanup.sh ${self.name} || true"
  }
}

# Policy granting the privileged user access to read the flag
resource "aws_iam_user_policy" "privileged_user_policy" {
  name = "${var.lab_prefix}-createcredentials-privileged-policy"
  user = aws_iam_user.privileged_user.name

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
      },
      {
        Sid    = "DescribeSelf"
        Effect = "Allow"
        Action = [
          "iam:GetUser",
          "iam:ListAccessKeys"
        ]
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/$${aws:username}"
      }
    ]
  })
}

# Entry role with limited permissions but can create credentials for other users
resource "aws_iam_role" "entry_role" {
  name                 = "${var.lab_prefix}-createcredentials-entry"
  description          = "Entry role with limited permissions for CreateCredentials lab"
  path                 = "/"
  permissions_boundary = aws_iam_policy.entry_role_boundary.arn

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
    Name        = "${var.lab_prefix}-createcredentials-entry"
    LabExercise = "CreateCredentials"
    Purpose     = "AttackerRole"
  }
}

# Entry role policy allowing credential creation for other users
resource "aws_iam_role_policy" "entry_role_policy" {
  name = "${var.lab_prefix}-createcredentials-entry-policy"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_prefix}-createcredentials-entry"
      },
      {
        Sid    = "DiscoverUsers"
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:GetUser",
          "iam:ListUserPolicies",
          "iam:GetUserPolicy",
          "iam:ListAttachedUserPolicies"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyAccessToFlag"
        Effect = "Deny"
        Action = [
          "iam:GetRole",
          "iam:ListRoleTags"
        ]
        Resource = aws_iam_role.flag_holder.arn
      },
      {
        Sid    = "EscalationVectorCreateAccessKey"
        Effect = "Allow"
        Action = [
          "iam:CreateAccessKey"
        ]
        Resource = aws_iam_user.privileged_user.arn
      },
      {
        Sid    = "EscalationVectorCreateLoginProfile"
        Effect = "Allow"
        Action = [
          "iam:CreateLoginProfile",
          "iam:GetLoginProfile"
        ]
        Resource = aws_iam_user.privileged_user.arn
      },
      {
        Sid    = "ListAccessKeys"
        Effect = "Allow"
        Action = [
          "iam:ListAccessKeys"
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
  name        = "${var.lab_prefix}-createcredentials-flag-holder"
  description = "IAM role that contains the CreateCredentials lab flag as a tag"

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
    Name        = "${var.lab_prefix}-createcredentials-flag-holder"
    flag        = var.flag_value
    lab         = "CreateCredentials"
    description = "Congratulations - You have successfully escalated privileges in the Specter AWS Lab"
  }
}

# Optional: Documentation policy showing what the privileged user has access to
resource "aws_iam_policy" "escalated_permissions" {
  name        = "${var.lab_prefix}-createcredentials-escalated"
  description = "Permissions the privileged user has (accessible via credential creation)"
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
    Name        = "${var.lab_prefix}-createcredentials-escalated"
    LabExercise = "CreateCredentials"
    Purpose     = "Documentation"
  }
}

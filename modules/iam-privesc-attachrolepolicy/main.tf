# Permission boundary for the target role to limit what it can do after policies are attached
resource "aws_iam_policy" "role_permission_boundary" {
  name        = "${var.lab_prefix}-attachrolepolicy-role-boundary"
  description = "Permission boundary for target role in AttachRolePolicy lab"
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
    Name        = "${var.lab_prefix}-attachrolepolicy-role-boundary"
    LabExercise = "AttachRolePolicy"
  }
}

# Permission boundary for the entry role
resource "aws_iam_policy" "entry_role_permission_boundary" {
  name        = "${var.lab_prefix}-attachrolepolicy-entry-boundary"
  description = "Permission boundary for entry role in AttachRolePolicy lab"
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
          "iam:AttachRolePolicy"
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
          "iam:AttachRolePolicy",
          "sts:AssumeRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.lab_prefix}-attachrolepolicy-entry-boundary"
    LabExercise = "AttachRolePolicy"
  }
}

# Data source to get current account ID
data "aws_caller_identity" "current" {}

# Target role with minimal permissions initially
# The entry role will attach additional policies to this role to escalate privileges
resource "aws_iam_role" "target_role" {
  name                 = "${var.lab_prefix}-attachrolepolicy-target"
  description          = "Target role for AttachRolePolicy privilege escalation lab"
  permissions_boundary = aws_iam_policy.role_permission_boundary.arn

  # Trust policy allows the entry role to assume this role
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
    Name        = "${var.lab_prefix}-attachrolepolicy-target"
    LabExercise = "AttachRolePolicy"
  }
}

# Initial inline policy on the role with minimal permissions
# Intentionally very limited - does NOT grant access to the flag
resource "aws_iam_role_policy" "target_role_initial" {
  name = "${var.lab_prefix}-attachrolepolicy-initial"
  role = aws_iam_role.target_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "MinimalPermissions"
        Effect = "Allow"
        Action = [
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies"
        ]
        Resource = aws_iam_role.target_role.arn
      }
    ]
  })
}

# Entry role with limited permissions but can attach policies to the target role
resource "aws_iam_role" "entry_role" {
  name                 = "${var.lab_prefix}-attachrolepolicy-entry"
  description          = "Entry role with limited permissions for AttachRolePolicy lab"
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
    Name        = "${var.lab_prefix}-attachrolepolicy-entry"
    LabExercise = "AttachRolePolicy"
  }
}

# Entry role policy allowing AttachRolePolicy and AssumeRole
resource "aws_iam_role_policy" "entry_role_policy" {
  name = "${var.lab_prefix}-attachrolepolicy-entry-policy"
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
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.lab_prefix}-attachrolepolicy-entry"
      },
      {
        Sid    = "DiscoverRoles"
        Effect = "Allow"
        Action = [
          "iam:ListRoles",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "EscalationVector"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy"
        ]
        Resource = aws_iam_role.target_role.arn
      },
      {
        Sid    = "AssumeTargetRole"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = aws_iam_role.target_role.arn
      },
      {
        Sid    = "ListPolicies"
        Effect = "Allow"
        Action = [
          "iam:ListPolicies",
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Resource = "*"
      }
    ]
  })
}

# Managed policy that grants access to read the flag
# The user will attach this to the target role during exploitation
resource "aws_iam_policy" "flag_access_policy" {
  name        = "${var.lab_prefix}-attachrolepolicy-flag-access"
  description = "Policy that grants access to read the flag - to be attached by user"
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
    Name        = "${var.lab_prefix}-attachrolepolicy-flag-access"
    LabExercise = "AttachRolePolicy"
    Purpose     = "EscalationTarget"
  }
}

# Null resource to detach managed policies from the target role on destroy
# This is needed because students manually attach policies during the lab
resource "null_resource" "detach_role_policies" {
  triggers = {
    role_name = aws_iam_role.target_role.name
    region    = data.aws_caller_identity.current.account_id
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      # Detach all managed policies from the role before destroying
      ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name ${self.triggers.role_name} --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || true)
      for policy_arn in $ATTACHED_POLICIES; do
        echo "Detaching policy $policy_arn from role ${self.triggers.role_name}"
        aws iam detach-role-policy --role-name ${self.triggers.role_name} --policy-arn $policy_arn 2>/dev/null || true
      done
    EOT
  }

  depends_on = [
    aws_iam_role.target_role,
    aws_iam_policy.flag_access_policy
  ]
}

# IAM role containing the flag as a tag for this lab
resource "aws_iam_role" "flag_holder" {
  name        = "${var.lab_prefix}-attachrolepolicy-flag-holder"
  description = "IAM role that contains the AttachRolePolicy lab flag as a tag"

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
    Name        = "${var.lab_prefix}-attachrolepolicy-flag-holder"
    flag        = var.flag_value
    lab         = "AttachRolePolicy"
    description = "Congratulations - You have successfully escalated privileges in the Specter AWS Lab"
  }
}

# Optional: Documentation policy showing what the target role should have after escalation
resource "aws_iam_policy" "escalated_permissions" {
  name        = "${var.lab_prefix}-attachrolepolicy-escalated"
  description = "Permissions the role should have after successful privilege escalation"
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
    Name        = "${var.lab_prefix}-attachrolepolicy-escalated"
    LabExercise = "AttachRolePolicy"
    Purpose     = "Documentation"
  }
}

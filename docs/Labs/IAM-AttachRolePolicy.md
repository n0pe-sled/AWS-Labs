# IAM Privilege Escalation: AttachRolePolicy

## Overview

This module demonstrates the **AttachRolePolicy** privilege escalation technique in AWS IAM. This vulnerability occurs when an IAM principal has the `iam:AttachRolePolicy` permission on a role they can assume, allowing them to attach managed policies with elevated permissions to that role.

## Attack Path

1. **Initial State**: The IAM user has limited permissions:
   - Can view their own user information
   - Can list and describe IAM roles and policies
   - Can attach managed policies to a specific target role
   - Can assume the target role

2. **Reconnaissance**: The attacker discovers:
   - A target role they can both modify and assume
   - Available managed policies with elevated permissions

3. **Exploitation**: The attacker attaches a managed policy to the target role:
   ```bash
   aws iam attach-role-policy \
     --role-name <target-role> \
     --policy-arn <policy-with-elevated-permissions>
   ```

4. **Privilege Escalation**: The attacker assumes the role with newly attached permissions:
   ```bash
   aws sts assume-role \
     --role-arn <target-role-arn> \
     --role-session-name escalated-session
   ```

5. **Post-Exploitation**: The attacker uses the temporary credentials to access privileged resources.

## Lab Objectives

- Understand how `iam:AttachRolePolicy` can be abused for privilege escalation
- Learn to identify vulnerable role configurations
- Practice exploiting the vulnerability to escalate privileges
- Understand the difference between AttachRolePolicy and other escalation vectors
- Learn mitigation strategies

## Resources Created

- `aws_iam_role.target_role`: A role with minimal initial permissions and a trust policy allowing the user to assume it
- `aws_iam_role_policy.target_role_initial`: Initial inline policy with minimal permissions
- `aws_iam_user.vulnerable_user`: An IAM user with AttachRolePolicy and AssumeRole permissions
- `aws_iam_user_policy.user_policy`: User policy granting the escalation vector
- `aws_iam_policy.flag_access_policy`: A managed policy granting access to the flag (to be attached)
- `aws_iam_access_key.vulnerable_user`: Access credentials for the lab user

## Initial Permissions

The user starts with:
- `iam:GetUser`, `iam:ListUserPolicies` (read-only IAM permissions on self)
- `iam:ListRoles`, `iam:GetRole`, `iam:ListAttachedRolePolicies`, `iam:ListRolePolicies`, `iam:GetRolePolicy` (enumerate roles)
- `iam:ListPolicies`, `iam:GetPolicy`, `iam:GetPolicyVersion` (enumerate managed policies)
- `iam:AttachRolePolicy` on the target role (**escalation vector**)
- `sts:AssumeRole` on the target role

The target role initially has:
- `iam:ListAttachedRolePolicies`, `iam:ListRolePolicies` on itself only (truly minimal permissions)
- **Does NOT have access to read the flag initially**

## Vulnerable Configuration

The user has permission to attach policies to a specific role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EscalationVector",
      "Effect": "Allow",
      "Action": ["iam:AttachRolePolicy"],
      "Resource": "arn:aws:iam::ACCOUNT_ID:role/target-role"
    },
    {
      "Sid": "AssumeTargetRole",
      "Effect": "Allow",
      "Action": ["sts:AssumeRole"],
      "Resource": "arn:aws:iam::ACCOUNT_ID:role/target-role"
    }
  ]
}
```

## Lab Goals

The goal is to:
1. Discover the target role and available managed policies
2. Attach a managed policy with elevated permissions to the target role
3. Assume the role to gain those permissions
4. Access the flag with the elevated privileges


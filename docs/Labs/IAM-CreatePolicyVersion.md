# IAM Privilege Escalation: CreatePolicyVersion

## Overview

This module demonstrates the **CreatePolicyVersion** privilege escalation technique in AWS IAM. This vulnerability occurs when an IAM principal has the `iam:CreatePolicyVersion` permission on a customer-managed policy that is attached to their own user or role.

## Attack Path

1. **Initial State**: The IAM user has limited permissions:
   - Can view their own user information
   - Can list and read policies attached to them
   - Can create new versions of a specific customer-managed policy

2. **Exploitation**: The attacker creates a new version of the policy with escalated privileges:
   ```bash
   aws iam create-policy-version \
     --policy-arn <policy-arn> \
     --policy-document file://escalated-policy.json \
     --set-as-default
   ```

3. **Post-Exploitation**: The new policy version is automatically applied, granting the attacker elevated permissions to:
   - Read IAM role information and tags
   - Retrieve the flag from the flag holder role's tags

## Resources Created

- `aws_iam_policy.vulnerable_policy`: A customer-managed policy with limited initial permissions
- `aws_iam_user.vulnerable_user`: An IAM user with the vulnerable policy attached
- `aws_iam_access_key.vulnerable_user`: Access credentials for the lab user

## Initial Permissions

The user starts with:
- `iam:GetUser`, `iam:ListAttachedUserPolicies`, `iam:GetPolicy`, etc. (read-only IAM permissions)
- `iam:CreatePolicyVersion` on the specific policy attached to the user

## Target Permissions

To retrieve the flag, you need:
- `iam:GetRole` on the flag holder role
- `iam:ListRoleTags` on the flag holder role
- `iam:ListRoles` to discover roles

## Lab Goals

- Understand how `iam:CreatePolicyVersion` can be abused for privilege escalation
- Learn to identify vulnerable IAM configurations
- Practice exploiting the vulnerability to retrieve the flag
- Understand mitigation strategies

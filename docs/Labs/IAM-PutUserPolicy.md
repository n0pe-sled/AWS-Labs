# IAM Privilege Escalation: PutUserPolicy

## Overview

This module demonstrates the **PutUserPolicy** privilege escalation technique in AWS IAM. This vulnerability occurs when an IAM user has the `iam:PutUserPolicy` permission on their own user account, allowing them to create or update inline policies attached to themselves.

## Attack Path

1. **Initial State**: The IAM user has limited permissions:
   - Can view their own user information
   - Can list and read inline policies attached to themselves
   - Can use `iam:PutUserPolicy` on their own user account

2. **Exploitation**: The attacker creates or updates an inline policy to grant themselves elevated privileges:
   ```bash
   aws iam put-user-policy \
     --user-name <username> \
     --policy-name escalated-policy \
     --policy-document file://escalated-policy.json
   ```

3. **Post-Exploitation**: The new inline policy is immediately applied, granting the attacker elevated permissions to access sensitive resources.

## Lab Objectives

- Understand how `iam:PutUserPolicy` can be abused for privilege escalation
- Learn to identify vulnerable IAM configurations
- Practice exploiting the vulnerability to escalate privileges
- Understand the difference between inline policies and managed policies
- Learn mitigation strategies

## Resources Created

- `aws_iam_user.vulnerable_user`: An IAM user with PutUserPolicy permissions on self
- `aws_iam_user_policy.initial_policy`: Initial inline policy with limited permissions
- `aws_iam_access_key.vulnerable_user`: Access credentials for the lab user

## Initial Permissions

The user starts with:
- `iam:GetUser` on themselves
- `iam:ListUserPolicies`, `iam:GetUserPolicy` on themselves
- `iam:PutUserPolicy` on themselves (**the escalation vector**)

## Vulnerable Configuration

The user has an inline policy allowing:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EscalationVector",
      "Effect": "Allow",
      "Action": ["iam:PutUserPolicy"],
      "Resource": "arn:aws:iam::ACCOUNT_ID:user/${aws:username}"
    }
  ]
}
```

## Lab Goals

The goal is to:
1. Use `iam:PutUserPolicy` to create a new inline policy granting elevated permissions
2. Access resources that were previously denied
3. Demonstrate successful privilege escalation


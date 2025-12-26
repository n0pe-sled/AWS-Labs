# IAM Privilege Escalation: AssumeRole

## Overview

This module demonstrates the **AssumeRole** privilege escalation technique in AWS IAM. This vulnerability occurs when an IAM role has an overly permissive trust policy that allows the entire AWS account root principal to assume it, rather than restricting it to specific principals.

## Attack Path

1. **Initial State**: The IAM user has limited permissions:
   - Can view their own user information
   - Can list and describe IAM roles
   - Can assume any role (via `sts:AssumeRole`)

2. **Reconnaissance**: The attacker discovers a role with an overly permissive trust policy:
   ```bash
   aws iam list-roles
   aws iam get-role --role-name <role-name>
   ```

3. **Exploitation**: The attacker assumes the privileged role:
   ```bash
   aws sts assume-role \
     --role-arn <privileged-role-arn> \
     --role-session-name attacker-session
   ```

4. **Post-Exploitation**: The attacker uses the temporary credentials to access privileged resources and retrieve the flag.

## Lab Objectives

- Understand how overly permissive trust policies enable privilege escalation
- Learn to identify vulnerable IAM role configurations
- Practice exploiting `sts:AssumeRole` to escalate privileges
- Understand the difference between secure and insecure trust policies
- Learn mitigation strategies

## Resources Created

- `aws_iam_role.privileged_role`: A role with an overly permissive trust policy
- `aws_iam_role_policy.privileged_policy`: Policy granting elevated permissions
- `aws_iam_user.vulnerable_user`: An IAM user with AssumeRole permissions
- `aws_iam_access_key.vulnerable_user`: Access credentials for the lab user

## Initial Permissions

The user starts with:
- `iam:GetUser`, `iam:ListUserPolicies` (read-only IAM permissions on self)
- `iam:ListRoles`, `iam:GetRole` (ability to enumerate roles)
- `sts:AssumeRole` on all resources

## Vulnerable Configuration

The privileged role's trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Lab Goals

The goal of this lab is to demonstrate the AssumeRole privilege escalation technique by:
1. Identifying a role with an overly permissive trust policy
2. Successfully assuming that role to gain elevated privileges
3. Understanding the security implications of trusting the AWS account root principal

**Note**: This lab focuses on demonstrating the AssumeRole technique itself. The "success" is successfully assuming the privileged role, not accessing a specific resource.


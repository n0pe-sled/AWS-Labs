# IAM Privilege Escalation: UpdateAssumeRolePolicy

## Overview

This lab demonstrates privilege escalation via the `iam:UpdateAssumeRolePolicy` permission. An attacker with this permission can modify the trust policy of an IAM role to allow themselves (or other principals) to assume it, thereby gaining the role's permissions.

The `iam:UpdateAssumeRolePolicy` permission allows modification of a role's trust policy (also called assume role policy). This policy controls **who** can assume the role, not what the role can do. By modifying this policy, an attacker can:

1. Add their own user or role as a trusted principal
2. Remove restrictive conditions from the trust policy
3. Broaden the trust policy to allow any principal in the account
4. Assume the modified role and gain its permissions

This is particularly dangerous when:
- The target role has elevated permissions
- The trust policy modification is not monitored
- The attacker has `sts:AssumeRole` permission to actually assume the modified role

## Lab Setup

### Resources Created

1. **Privileged Role** (`specter-lab-updateassumerolepolicy-privileged`)
   - Has permission to read the flag from the IAM role tags
   - Initial trust policy denies all principals from assuming it
   - Can be modified by the vulnerable user

2. **Vulnerable User** (`specter-lab-updateassumerolepolicy-user`)
   - Has `iam:UpdateAssumeRolePolicy` on the privileged role (**escalation vector**)
   - Has `sts:AssumeRole` to assume roles after modifying trust policies
   - Has IAM read permissions to discover roles and policies
   - Provided with access keys for authentication

### Initial State

- The vulnerable user **cannot** assume the privileged role initially
- The privileged role's trust policy denies all principals
- The user can view and modify the trust policy

## Attack Path

1. **Reconnaissance**: Discover the privileged role and its permissions
2. **Analyze Trust Policy**: Examine the current assume role policy
3. **Modify Trust Policy**: Use `iam:UpdateAssumeRolePolicy` to add your user as a trusted principal
4. **Assume Role**: Use `sts:AssumeRole` to assume the modified role
5. **Access Resources**: Use the role's permissions to access the flag

## Vulnerable Configuration

The vulnerable user has the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EscalationVectorUpdateAssumeRolePolicy",
      "Effect": "Allow",
      "Action": ["iam:UpdateAssumeRolePolicy"],
      "Resource": "arn:aws:iam::ACCOUNT:role/specter-lab-updateassumerolepolicy-privileged"
    },
    {
      "Sid": "AssumeModifiedRole",
      "Effect": "Allow",
      "Action": ["sts:AssumeRole"],
      "Resource": "arn:aws:iam::ACCOUNT:role/specter-lab-updateassumerolepolicy-privileged"
    }
  ]
}
```

## Lab Goals

- Understand the difference between trust policies and permission policies
- Learn how trust policies control role assumption
- Practice modifying IAM role trust policies
- Understand the implications of `iam:UpdateAssumeRolePolicy` permission
- Learn detection and prevention strategies for this technique

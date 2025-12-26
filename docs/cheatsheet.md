# AWS CLI Cheatsheet for IAM Security Testing

A comprehensive reference guide for AWS CLI commands commonly used in IAM privilege escalation labs and security testing.

## Table of Contents

- [AWS Configuration](#aws-configuration)
- [Identity & STS Commands](#identity--sts-commands)
- [IAM User Commands](#iam-user-commands)
- [IAM Role Commands](#iam-role-commands)
- [IAM Policy Commands](#iam-policy-commands)
- [Access Keys & Credentials](#access-keys--credentials)
- [Common Workflows](#common-workflows)
- [CloudTrail & Detection](#cloudtrail--detection)
- [JSON & jq Tips](#json--jq-tips)

---

## AWS Configuration

### Set AWS Credentials

```bash
# Export credentials as environment variables
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"

# Unset session token (when switching from role to user credentials)
unset AWS_SESSION_TOKEN
```

### Configure AWS CLI Profile

```bash
# Configure a named profile
aws configure --profile myprofile

# Use a specific profile
export AWS_PROFILE=myprofile

# Or use --profile flag with each command
aws sts get-caller-identity --profile myprofile
```

---

## Identity & STS Commands

### Get Current Identity

```bash
# Show who you are currently authenticated as
aws sts get-caller-identity | jq

# Extract specific fields
aws sts get-caller-identity --query 'Arn' --output text
aws sts get-caller-identity --query 'Account' --output text
```

### Assume Role

```bash
# Assume a role and save credentials
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/MyRole \
  --role-session-name my-session \
  --output json > /tmp/role-creds.json

# Export assumed role credentials
export AWS_ACCESS_KEY_ID=$(cat /tmp/role-creds.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/role-creds.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/role-creds.json | jq -r '.Credentials.SessionToken')

# One-liner to assume role and export credentials
read AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< \
  $(aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/MyRole \
    --role-session-name my-session \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)
```

### Get Session Token (MFA)

```bash
# Get session token with MFA
aws sts get-session-token \
  --serial-number arn:aws:iam::123456789012:mfa/user \
  --token-code 123456 \
  --duration-seconds 3600
```

---

## IAM User Commands

### List & Get Users

```bash
# List all IAM users
aws iam list-users | jq

# List users with specific fields
aws iam list-users --query 'Users[*].[UserName,Arn]' --output table

# Get current user name from ARN
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo $USER_NAME

# Get details about a specific user
aws iam get-user --user-name myuser | jq
```

### User Policies

```bash
# List inline policies attached to a user
aws iam list-user-policies --user-name myuser | jq

# Get inline policy document
aws iam get-user-policy \
  --user-name myuser \
  --policy-name mypolicy | jq

# List managed policies attached to a user
aws iam list-attached-user-policies --user-name myuser | jq
```

### Create & Modify User Policies

```bash
# Put (create or update) an inline policy on a user
aws iam put-user-policy \
  --user-name myuser \
  --policy-name mypolicy \
  --policy-document file://policy.json

# Attach a managed policy to a user
aws iam attach-user-policy \
  --user-name myuser \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Detach a managed policy from a user
aws iam detach-user-policy \
  --user-name myuser \
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

# Delete an inline policy from a user
aws iam delete-user-policy \
  --user-name myuser \
  --policy-name mypolicy
```

---

## IAM Role Commands

### List & Get Roles

```bash
# List all IAM roles
aws iam list-roles | jq

# List roles with specific fields
aws iam list-roles --query 'Roles[*].[RoleName,Arn,Description]' --output table

# Get details about a specific role
aws iam get-role --role-name myrole | jq

# Get just the trust policy (AssumeRolePolicyDocument)
aws iam get-role --role-name myrole --query 'Role.AssumeRolePolicyDocument' | jq
```

### Role Policies

```bash
# List inline policies attached to a role
aws iam list-role-policies --role-name myrole | jq

# Get inline policy document
aws iam get-role-policy \
  --role-name myrole \
  --policy-name mypolicy | jq

# List managed policies attached to a role
aws iam list-attached-role-policies --role-name myrole | jq
```

### Modify Role Policies

```bash
# Put (create or update) an inline policy on a role
aws iam put-role-policy \
  --role-name myrole \
  --policy-name mypolicy \
  --policy-document file://policy.json

# Attach a managed policy to a role
aws iam attach-role-policy \
  --role-name myrole \
  --policy-arn arn:aws:iam::123456789012:policy/mypolicy

# Detach a managed policy from a role
aws iam detach-role-policy \
  --role-name myrole \
  --policy-arn arn:aws:iam::123456789012:policy/mypolicy

# Delete an inline policy from a role
aws iam delete-role-policy \
  --role-name myrole \
  --policy-name mypolicy
```

### Update Trust Policy

```bash
# Update a role's trust policy (AssumeRolePolicyDocument)
aws iam update-assume-role-policy \
  --role-name myrole \
  --policy-document file://trust-policy.json
```

### Role Tags

```bash
# List tags on a role
aws iam list-role-tags --role-name myrole | jq

# Get specific tag value from a role
aws iam get-role \
  --role-name myrole \
  --query 'Role.Tags[?Key==`flag`].Value' \
  --output text
```

---

## IAM Policy Commands

### List & Get Policies

```bash
# List all customer-managed policies
aws iam list-policies --scope Local | jq

# List AWS-managed policies
aws iam list-policies --scope AWS | jq

# List policies with specific fields
aws iam list-policies --scope Local \
  --query 'Policies[*].[PolicyName,Arn,Description]' \
  --output table

# Get policy ARN by name
POLICY_ARN=$(aws iam list-policies --scope Local \
  --query 'Policies[?PolicyName==`mypolicy`].Arn' \
  --output text)

# Get policy metadata
aws iam get-policy --policy-arn $POLICY_ARN | jq

# Get policy document (requires version ID)
POLICY_VERSION=$(aws iam get-policy --policy-arn $POLICY_ARN \
  --query 'Policy.DefaultVersionId' --output text)

aws iam get-policy-version \
  --policy-arn $POLICY_ARN \
  --version-id $POLICY_VERSION | jq
```

### Create & Modify Policies

```bash
# Create a new managed policy
aws iam create-policy \
  --policy-name mypolicy \
  --policy-document file://policy.json

# Create a new policy version
aws iam create-policy-version \
  --policy-arn arn:aws:iam::123456789012:policy/mypolicy \
  --policy-document file://new-policy.json \
  --set-as-default

# List all versions of a policy
aws iam list-policy-versions --policy-arn $POLICY_ARN | jq

# Set a specific version as default
aws iam set-default-policy-version \
  --policy-arn $POLICY_ARN \
  --version-id v2

# Delete a policy version (non-default only)
aws iam delete-policy-version \
  --policy-arn $POLICY_ARN \
  --version-id v1

# Delete a policy (must delete all non-default versions first)
aws iam delete-policy --policy-arn $POLICY_ARN
```

---

## Access Keys & Credentials

### List & Create Access Keys

```bash
# List access keys for a user
aws iam list-access-keys --user-name myuser | jq

# Create new access key for a user
aws iam create-access-key --user-name myuser | jq

# Important: Save the SecretAccessKey - it's only shown once!

# Delete an access key
aws iam delete-access-key \
  --user-name myuser \
  --access-key-id AKIA...

# Update access key status (activate/deactivate)
aws iam update-access-key \
  --user-name myuser \
  --access-key-id AKIA... \
  --status Inactive
```

### Console Login Profiles

```bash
# Get login profile (console password) for a user
aws iam get-login-profile --user-name myuser | jq

# Create login profile (console password) for a user
aws iam create-login-profile \
  --user-name myuser \
  --password 'MySecurePassword123!'

# Create login profile without password reset required
aws iam create-login-profile \
  --user-name myuser \
  --password 'MySecurePassword123!' \
  --no-password-reset-required

# Update login profile password
aws iam update-login-profile \
  --user-name myuser \
  --password 'NewPassword123!'

# Delete login profile
aws iam delete-login-profile --user-name myuser
```

### Get Console Sign-In URL

```bash
# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# Account-specific sign-in URL
echo "Console URL: https://$ACCOUNT_ID.signin.aws.amazon.com/console"

# Generic sign-in URL
echo "Console URL: https://console.aws.amazon.com/"
```

---

## Common Workflows

### Enumerate Current User Permissions

```bash
# Get current user name
USER_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)

# List all inline policies
aws iam list-user-policies --user-name $USER_NAME | jq

# Get each inline policy document
for policy in $(aws iam list-user-policies --user-name $USER_NAME --query 'PolicyNames[]' --output text); do
  echo "Policy: $policy"
  aws iam get-user-policy --user-name $USER_NAME --policy-name $policy | jq
done

# List all attached managed policies
aws iam list-attached-user-policies --user-name $USER_NAME | jq
```

### Discover Roles You Can Assume

```bash
# List all roles
aws iam list-roles --query 'Roles[*].RoleName' --output text

# Check a specific role's trust policy
aws iam get-role --role-name myrole \
  --query 'Role.AssumeRolePolicyDocument' | jq

# Try to assume the role
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/myrole \
  --role-session-name test-session
```

### Find Managed Policies with Specific Permissions

```bash
# List all customer-managed policies
aws iam list-policies --scope Local | jq

# Get policy document for each policy to search for specific actions
for policy_arn in $(aws iam list-policies --scope Local --query 'Policies[].Arn' --output text); do
  version=$(aws iam get-policy --policy-arn $policy_arn --query 'Policy.DefaultVersionId' --output text)
  echo "Checking: $policy_arn"
  aws iam get-policy-version --policy-arn $policy_arn --version-id $version | jq
done
```

### Audit All IAM Users and Their Credentials

```bash
# List all users with their access keys
aws iam list-users | jq -r '.Users[].UserName' | while read user; do
  echo "User: $user"
  aws iam list-access-keys --user-name $user | jq
  aws iam get-login-profile --user-name $user 2>/dev/null || echo "  No login profile"
done
```

---

## CloudTrail & Detection

### Query CloudTrail Events

```bash
# Look up events by event name
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateAccessKey \
  --max-results 10 | jq

# Look up events by username
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=myuser \
  --max-results 50 | jq

# Look up events within a time range
aws cloudtrail lookup-events \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T23:59:59Z \
  --max-results 100 | jq
```

### Common Detection Queries

```bash
# Detect CreateAccessKey events where user created keys for different user
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateAccessKey \
  --max-results 50 | jq

# Detect UpdateAssumeRolePolicy events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=UpdateAssumeRolePolicy \
  --max-results 10 | jq

# Detect AttachRolePolicy events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AttachRolePolicy \
  --max-results 10 | jq

# Detect CreatePolicyVersion events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreatePolicyVersion \
  --max-results 10 | jq

# Detect PutUserPolicy events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=PutUserPolicy \
  --max-results 10 | jq

# Detect AssumeRole events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-results 20 | jq
```

### CloudWatch Logs Insights Queries

```
# Detect credential creation for other users
fields @timestamp, userIdentity.arn as Creator, requestParameters.userName as Target
| filter eventName in ["CreateAccessKey", "CreateLoginProfile"]
| filter userIdentity.arn not like requestParameters.userName
| sort @timestamp desc

# Detect trust policy modifications
fields @timestamp, userIdentity.arn as Actor, requestParameters.roleName as TargetRole
| filter eventName = "UpdateAssumeRolePolicy"
| sort @timestamp desc

# Detect policy attachments
fields @timestamp, userIdentity.arn, requestParameters.roleName, requestParameters.policyArn
| filter eventName = "AttachRolePolicy"
| sort @timestamp desc

# Detect inline policy modifications
fields @timestamp, userIdentity.arn, requestParameters.userName, requestParameters.policyDocument
| filter eventName = "PutUserPolicy"
| sort @timestamp desc

# Detect policy version creation
fields @timestamp, userIdentity.arn, requestParameters.policyArn
| filter eventName = "CreatePolicyVersion"
| sort @timestamp desc

# Correlation: Policy change followed by AssumeRole
fields @timestamp, eventName, userIdentity.arn, requestParameters
| filter eventName in ["UpdateAssumeRolePolicy", "AssumeRole", "AttachRolePolicy"]
| sort @timestamp asc
```

---

## JSON & jq Tips

### Basic jq Usage

```bash
# Pretty-print JSON
aws iam get-user --user-name myuser | jq

# Extract specific field
aws sts get-caller-identity | jq -r '.Arn'

# Extract multiple fields
aws sts get-caller-identity | jq -r '.Account, .UserId, .Arn'

# Filter array elements
aws iam list-users | jq '.Users[] | select(.UserName == "myuser")'

# Get array length
aws iam list-users | jq '.Users | length'

# Extract from nested objects
aws iam get-role --role-name myrole | jq '.Role.AssumeRolePolicyDocument'
```

### Advanced jq Patterns

```bash
# Get all user names
aws iam list-users | jq -r '.Users[].UserName'

# Get users created after a specific date
aws iam list-users | jq '.Users[] | select(.CreateDate > "2024-01-01")'

# Extract specific tag value
aws iam get-role --role-name myrole | jq -r '.Role.Tags[] | select(.Key=="Environment") | .Value'

# Compact output (no whitespace)
aws iam list-users | jq -c

# Raw output (no quotes for strings)
aws iam list-users | jq -r '.Users[0].UserName'

# Sort by a field
aws iam list-users | jq '.Users | sort_by(.CreateDate)'

# Count items matching a condition
aws iam list-users | jq '[.Users[] | select(.PasswordLastUsed != null)] | length'
```

### Working with AWS CLI Query Parameter

```bash
# Use --query instead of jq for simpler extractions
aws iam list-users --query 'Users[*].UserName' --output text

# Extract nested fields
aws iam get-role --role-name myrole \
  --query 'Role.AssumeRolePolicyDocument' \
  --output json | jq

# Filter with query
aws iam list-users \
  --query 'Users[?UserName==`myuser`]' \
  --output json | jq

# Table output for readability
aws iam list-users \
  --query 'Users[*].[UserName,CreateDate,Arn]' \
  --output table
```

### Combining Commands

```bash
# Save to variable
USER_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)

# Use in another command
aws iam get-user --user-name $(echo $USER_ARN | cut -d'/' -f2)

# Pipe through multiple filters
aws iam list-policies --scope Local | \
  jq -r '.Policies[].Arn' | \
  head -5

# Loop through results
for role in $(aws iam list-roles --query 'Roles[*].RoleName' --output text); do
  echo "Role: $role"
  aws iam get-role --role-name $role | jq '.Role.AssumeRolePolicyDocument'
done
```

---

## Policy Document Examples

### Trust Policy (AssumeRolePolicyDocument)

Allow a specific user to assume a role:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789012:user/myuser"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

Allow any user in the account to assume a role (overly permissive):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789012:root"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

---

## Useful One-Liners

```bash
# Get your current user name
aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2

# Get your account ID
aws sts get-caller-identity --query 'Account' --output text

# Count total IAM users
aws iam list-users --query 'Users | length(@)'

# List all role names
aws iam list-roles --query 'Roles[*].RoleName' --output text

# Find roles with no permission boundary
aws iam list-roles | jq -r '.Roles[] | select(.PermissionsBoundary == null) | .RoleName'

# Find users with console access
aws iam list-users | jq -r '.Users[].UserName' | while read user; do
  aws iam get-login-profile --user-name $user 2>/dev/null && echo $user
done

# Find users with access keys
aws iam list-users | jq -r '.Users[].UserName' | while read user; do
  count=$(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata | length(@)')
  if [ $count -gt 0 ]; then echo "$user: $count keys"; fi
done

# Get all customer-managed policy ARNs
aws iam list-policies --scope Local --query 'Policies[*].Arn' --output text

# Check if current credentials are temporary (have session token)
if [ -n "$AWS_SESSION_TOKEN" ]; then echo "Using temporary credentials"; else echo "Using long-term credentials"; fi
```

---

## Additional Resources

- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/)
- [AWS IAM API Reference](https://docs.aws.amazon.com/IAM/latest/APIReference/)
- [AWS STS API Reference](https://docs.aws.amazon.com/STS/latest/APIReference/)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [AWS CloudTrail User Guide](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

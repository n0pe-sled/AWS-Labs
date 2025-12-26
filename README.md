# Specter AWS Lab - AWS Attack Paths Learning Environment

A modular Terraform infrastructure-as-code project designed to create hands-on labs for learning AWS privilege escalation techniques and attack paths. Each module demonstrates a specific vulnerability or misconfiguration that can be exploited to escalate privileges and retrieve a flag.

## Disclaimer

This tool creates intentionally vulnerable infrastructure for educational purposes. The maintainers are not responsible for misuse or damage caused by this tool. Always obtain proper authorization before conducting security testing.


## Overview

This lab environment is designed for security researchers, cloud security professionals, and students to practice identifying and exploiting AWS IAM privilege escalation vulnerabilities in a safe, controlled environment.

### Features

- **Modular Design**: Enable/disable specific lab exercises independently
- **GitHub Actions Integration**: One-click deployment and teardown via checkbox selection
- **Remote State Management**: S3-backed Terraform state ensures proper resource tracking between runs
- **Educational Focus**: Detailed documentation with learning objectives and mitigation strategies
- **Realistic Scenarios**: IAM principals have only the exact permissions needed for the attack
- **Capture-the-Flag**: Successfully exploiting vulnerabilities reveals flags stored as IAM role tags
- **Cost Effective**: Labs use only IAM resources (no EC2, RDS, etc.) and can be destroyed when not in use

## Prerequisites

- AWS account with permissions to create IAM resources
- AWS IAM user with programmatic access (access key and secret key)
- GitHub account (for forking and running GitHub Actions)
- (Optional for local deployment) [Terraform](https://www.terraform.io/downloads) >= 1.0 or [OpenTofu](https://opentofu.org/)

## AWS CLI Cheatsheet

New to AWS CLI or need a quick reference? Check out the [AWS CLI Cheatsheet](docs/cheatsheet.md) for comprehensive examples of:
- AWS configuration and credential management
- IAM user, role, and policy commands
- STS operations and role assumption
- CloudTrail detection queries
- Common workflows and jq tips

## Quick Start

### Recommended: GitHub Actions Deployment

The easiest way to use this lab is to fork the repository and deploy labs using GitHub Actions:

#### 1. Fork this Repository

Click the "Fork" button at the top right of this repository to create your own copy.

#### 2. Create an AWS User with the Following Minimum Permissions:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "STS",
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMRoles",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:ListRoles",
                "iam:ListInstanceProfilesForRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMRolePolicies",
            "Effect": "Allow",
            "Action": [
                "iam:DeleteRolePolicy",
                "iam:GetRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:ListRolePolicies",
                "iam:PutRolePolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMManagedPolicies",
            "Effect": "Allow",
            "Action": [
                "iam:CreatePolicy",
                "iam:DeletePolicy",
                "iam:GetPolicy",
                "iam:GetPolicyVersion",
                "iam:ListPolicies",
                "iam:ListPolicyVersions"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMUsers",
            "Effect": "Allow",
            "Action": [
                "iam:CreateUser",
                "iam:DeleteUser",
                "iam:GetLoginProfile",
                "iam:GetUser",
                "iam:ListGroupsForUser",
                "iam:ListUsers"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMUserPolicies",
            "Effect": "Allow",
            "Action": [
                "iam:AttachUserPolicy",
                "iam:DetachUserPolicy",
                "iam:DeleteUserPolicy",
                "iam:GetUserPolicy",
                "iam:ListAttachedUserPolicies",
                "iam:PutUserPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMAccessKeys",
            "Effect": "Allow",
            "Action": [
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:ListAccessKeys"
            ],
            "Resource": "*"
        },
        {
            "Sid": "IAMTagging",
            "Effect": "Allow",
            "Action": [
                "iam:ListRoleTags",
                "iam:ListPolicyTags",
                "iam:TagRole",
                "iam:TagPolicy",
                "iam:TagUser",
                "iam:UntagPolicy",
                "iam:UntagRole",
                "iam:UntagUser"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:GetObject",
                "s3:PutBucketVersioning",
                "s3:GetBucketVersioning",
                "s3:GetObjectVersion",
                "s3:PutEncryptionConfiguration",
                "s3:GetEncryptionConfiguration",
                "s3:PutBucketPublicAccessBlock",
                "s3:ListBucket",
                "s3:ListBucketVersions"
            ],
            "Resource": "*"
        }
    ]
}
```

#### 3. Create AWS Access Keys for the newly created AWS User:
1. Log into AWS Console
2. Go to IAM -> Users -> Your User -> Security credentials
3. Click "Create access key"
4. Choose "Command Line Interface (CLI)"
5. Copy both the Access Key ID and Secret Access Key

#### 4. Configure AWS Credentials as Secrets

In your forked repository, go to **Settings** -> **Secrets and variables** -> **Actions**, then click **New repository secret** and add:

- **Name**: `AWS_ACCESS_KEY_ID`
  - **Value**: Your AWS access key ID

- **Name**: `AWS_SECRET_ACCESS_KEY`
  - **Value**: Your AWS secret access key

#### 5. Deploy Labs using GitHub Actions

1. Go to the **Actions** tab in your forked repository
2. Select **Deploy Labs** workflow (on the left sidebar)
3. Click the **Run workflow** dropdown button (on the right side)
4. Check the boxes for the labs you want to deploy:
   - [X] CreatePolicyVersion Lab
   - [ ] AssumeRole Lab
   - [ ] PutUserPolicy Lab
   - [ ] AttachRolePolicy Lab
   - [ ] CreateAccessKey/CreateLoginProfile Lab
   - [ ] UpdateAssumeRolePolicy Lab

5. Click the green **Run workflow** button to start deployment


The deployment typically takes 1-2 minutes. You can watch the progress in the workflow run page.

#### 4. Retrieve Lab Credentials

After the workflow completes, check the **deployment summary** at the top of the workflow run page. The credentials will be formatted as ready-to-use export commands that you can copy and paste directly into your terminal.

#### 5. Complete the Labs!

Use the credentials to configure your AWS CLI and start the labs. See [Available Labs](#lab-modules) below for instructions and walkthroughs.

#### 6. Destroy Labs When Done

To avoid AWS costs, destroy the labs when you're finished:

1. Go to **Actions** tab in your repository
2. Select **Destroy Labs** workflow (on the left sidebar)
3. Click **Run workflow**
4. Click **Run workflow** button to confirm

**Note:** Terraform will automatically detect which resources were deployed using the S3 remote state. No need to select individual labs - the state file tracks everything!

#### 7. List Currently Deployed Labs

To see which labs are currently deployed and get visibility into your AWS resources:

1. Go to **Actions** tab in your repository
2. Select **List Deployed Labs** workflow (on the left sidebar)
3. Click **Run workflow**
4. Click **Run workflow** button to confirm

The workflow will display:
- Active lab modules and their users
- IAM roles with permission boundary status
- Summary statistics (users, roles, policies)
- Resource health checks

**Automated Monitoring:** This workflow runs automatically every day at 9 AM UTC to provide visibility into deployed resources and help prevent forgotten labs from incurring unnecessary costs.

### Alternative: Local Deployment

If you prefer to deploy locally:

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/specter-aws-lab.git
cd specter-aws-lab

# Configure AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"

# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 bucket for Terraform state (one-time setup)
BUCKET_NAME="specter-lab-tfstate-${AWS_ACCOUNT_ID}"
aws s3api create-bucket --bucket "$BUCKET_NAME" --region us-east-1
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket "$BUCKET_NAME" \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Initialize Terraform with S3 backend
terraform init \
  -backend-config="bucket=$BUCKET_NAME" \
  -backend-config="region=us-east-1"

# Deploy labs
terraform apply

# Get credentials
terraform output -json
```

**Note:** The S3 bucket for state is automatically created and managed by GitHub Actions. For local use, you need to create it manually (see commands above) or use the same bucket.

## Lab Modules

### Available Labs

| # | Lab Name | IAM Permission | Lab Instructions | Walkthrough |
|---|----------|----------------|------------------|-------------|
| 1 | **CreatePolicyVersion** | `iam:CreatePolicyVersion` | [Instructions](docs/Labs/IAM-CreatePolicyVersion.md) | [Walkthrough](docs/Walkthroughs/IAM-CreatePolicyVersion.md) |
| 2 | **AssumeRole** | `sts:AssumeRole` | [Instructions](docs/Labs/IAM-AssumeRole.md) | [Walkthrough](docs/Walkthroughs/IAM-AssumeRole.md) |
| 3 | **PutUserPolicy** | `iam:PutUserPolicy` | [Instructions](docs/Labs/IAM-PutUserPolicy.md) | [Walkthrough](docs/Walkthroughs/IAM-PutUserPolicy.md) |
| 4 | **AttachRolePolicy** | `iam:AttachRolePolicy` | [Instructions](docs/Labs/IAM-AttachRolePolicy.md) | [Walkthrough](docs/Walkthroughs/IAM-AttachRolePolicy.md) |
| 5 | **CreateCredentials** | `iam:CreateAccessKey`<br>`iam:CreateLoginProfile` | [Instructions](docs/Labs/IAM-CreateCredentials.md) | [Walkthrough](docs/Walkthroughs/IAM-CreateCredentials.md) |
| 6 | **UpdateAssumeRolePolicy** | `iam:UpdateAssumeRolePolicy` | [Instructions](docs/Labs/IAM-UpdateAssumeRolePolicy.md) | [Walkthrough](docs/Walkthroughs/IAM-UpdateAssumeRolePolicy.md) |

### Lab Descriptions

#### 1. CreatePolicyVersion
Exploit `iam:CreatePolicyVersion` to modify a managed policy and grant yourself additional permissions.

#### 2. AssumeRole
Discover and assume an IAM role with overly permissive trust policies to escalate privileges.

#### 3. PutUserPolicy
Use `iam:PutUserPolicy` to attach a new inline policy to your own user, granting elevated permissions.

#### 4. AttachRolePolicy
Attach a managed policy to a role you can assume, escalating your privileges through role assumption.

#### 5. CreateCredentials
Create access keys or console passwords for privileged users using `iam:CreateAccessKey` and `iam:CreateLoginProfile`.

#### 6. UpdateAssumeRolePolicy
Modify a role's trust policy to allow yourself to assume it, gaining access to the role's permissions.

### Enabling Labs

**With GitHub Actions (Recommended):**

Simply check the boxes for the labs you want when running the workflow - no file editing required!

**For Local Deployment:**

Create a `terraform.tfvars` file:

```hcl
enable_createpolicyversion_lab = true
enable_assumerole_lab = true
enable_putuserpolicy_lab = true
enable_attachrolepolicy_lab = true
enable_createcredentials_lab = true
enable_updateassumerolepolicy_lab = true
```

Or edit `variables.tf` to change the default values to `true` for the labs you want.

### Coming Soon

**Compute & Service Labs:**
- **EC2 Privilege Escalation** - Instance metadata service (IMDS) exploitation, user data abuse, SSM abuse, etc.
- **Lambda Privilege Escalation** - Function manipulation, `iam:PassRole` attacks, etc.
- **CloudFormation Privilege Escalation** - Stack template injection and resource manipulation

**Identity Federation Labs:**
- **OIDC Provider Privilege Escalation** - Federated identity trust relationship abuse
- **SAML Provider Privilege Escalation** - SAML assertion manipulation

## Working with Labs

### Retrieving Lab Credentials

After deploying with GitHub Actions or locally, retrieve credentials:

**Via GitHub Actions:**
- Check the deployment summary at the top of the workflow run page
- Credentials will be formatted as export commands in code blocks ready to copy and paste

**Via Local Terraform:**
```bash
# View all lab outputs
terraform output

# Get specific lab credentials (add -json for sensitive values)
terraform output -json createpolicyversion_access_key_id
terraform output -json createpolicyversion_secret_access_key

# Export all outputs to a file
terraform output -json > lab-credentials.json
```

**Lab-Specific Outputs:**

Each enabled lab provides outputs in this format: `<labname>_<output>`. For example:
- `createpolicyversion_user_name`
- `createpolicyversion_access_key_id`
- `createpolicyversion_secret_access_key`
- `assumerole_user_name`
- `assumerole_access_key_id`
- etc.

### Configuring AWS CLI for Lab User

```bash
export AWS_ACCESS_KEY_ID="<access_key_from_output>"
export AWS_SECRET_ACCESS_KEY="<secret_key_from_output>"
export AWS_DEFAULT_REGION="us-east-1"

# Verify identity
aws sts get-caller-identity
```

### Retrieving the Flag

Each lab has its own unique flag stored in a lab-specific IAM role. After successfully escalating privileges, retrieve the flag using the role name for your specific lab:

**Flag Role Naming Pattern:** `specter-lab-<labname>-flag-holder`

Examples:
- CreatePolicyVersion: `specter-lab-createpolicyversion-flag-holder`
- AssumeRole: `specter-lab-assumerole-flag-holder`
- PutUserPolicy: `specter-lab-putuserpolicy-flag-holder`
- AttachRolePolicy: `specter-lab-attachrolepolicy-flag-holder`
- CreateCredentials: `specter-lab-createcredentials-flag-holder`
- UpdateAssumeRolePolicy: `specter-lab-updateassumerolepolicy-flag-holder`

```bash
# Replace <labname> with your specific lab (e.g., createpolicyversion, assumerole)
aws iam get-role \
  --role-name specter-lab-<labname>-flag-holder \
  --query 'Role.Tags[?Key==`flag`].Value' \
  --output text
```

Or to see the full message with lab information:

```bash
aws iam list-role-tags \
  --role-name specter-lab-<labname>-flag-holder
```

## Security Considerations

### For Lab Operators

- **This lab creates intentionally vulnerable IAM configurations**
- Only deploy in isolated AWS accounts dedicated to security training
- Regularly review CloudTrail logs for unexpected activity
- Set up billing alerts to prevent unexpected costs
- Use AWS Organizations SCPs to enforce account boundaries
- Destroy resources when not in use: `terraform destroy`

### For Lab Students

- Only use provided credentials in the designated lab environment
- Do not attempt these techniques in production environments
- Report any unintended access or issues to the lab operator
- Respect the scope of each lab exercise

## Monitoring and Logging

All lab activity is logged via AWS CloudTrail. To monitor lab usage:

```bash
# View recent IAM API calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=specter-lab-createpolicyversion-user \
  --max-results 50
```

## Cleanup

### Destroy Lab Infrastructure

**IMPORTANT:** Always destroy labs when not in use to avoid unnecessary AWS costs!

**Via GitHub Actions (Recommended):**
1. Go to **Actions** tab in your repository
2. Select **Destroy Labs** workflow (left sidebar)
3. Click **Run workflow**
4. Click **Run workflow** button to confirm

The destroy process will automatically remove all lab resources tracked in the Terraform state from your AWS account.

**Via Local Terraform:**
```bash
terraform destroy
```

**Note:** Thanks to S3 remote state tracking, Terraform automatically knows which resources were deployed. You don't need to remember or specify which labs to destroy - the state file handles this for you!

### State Management

This project uses **S3 remote state** to track deployed resources across GitHub Actions runs. This ensures:

- **Proper destruction**: Terraform knows exactly what resources were created
- **State persistence**: State survives between workflow runs
- **Version history**: S3 versioning provides state file history

**State Bucket Details:**
- **Name**: `specter-lab-tfstate-{AWS_ACCOUNT_ID}`
- **Location**: Same region as labs (us-east-1)
- **Features**: Versioning enabled, encryption enabled, public access blocked
- **Lifecycle**: Created automatically by GitHub Actions on first run

**Important:** The S3 state bucket is NOT automatically deleted when you destroy labs. This is intentional to preserve state history. To fully clean up:

```bash
# List the bucket name
aws sts get-caller-identity --query Account --output text

# Delete the state bucket (optional - only if you're done with the labs permanently)
aws s3 rb s3://specter-lab-tfstate-YOUR_ACCOUNT_ID --force
```

## Contributing

Contributions are welcome! To add a new lab module:

### 1. Create Module Infrastructure

Create a new module directory: `modules/iam-privesc-<technique>/`

Include the following files:
- `main.tf` - IAM resources for the lab
- `variables.tf` - Module variables (lab_prefix, etc.)
- `outputs.tf` - Output credentials (user_name, access_key_id, secret_access_key)

### 2. Add Root Configuration

- Add module invocation in root `main.tf` with count-based enablement
- Add enable/disable variable in root `variables.tf` (e.g., `enable_<technique>_lab`)
- Add module outputs in root `outputs.tf` for credentials

### 3. Create Documentation

Create lab documentation in the following locations:

**Instructions**: `docs/Labs/IAM-<Technique>.md`
- Describe the vulnerability
- List learning objectives
- Explain the attack scenario
- Document mitigation strategies

**Walkthrough**: `docs/Walkthroughs/IAM-<Technique>.md` or `modules/iam-privesc-<technique>/SOLUTION.md`
- Step-by-step exploitation guide
- CLI commands with expected outputs
- Flag retrieval instructions

### 4. Update Workflows

Add the new lab to `.github/workflows/deploy.yml`:
- Add checkbox input for the lab
- Add `-var` flag in Terraform plan/apply steps
- Add `print_lab_exports` call with paths to instructions and walkthrough

### 5. Update README

Add the lab to the "Available Labs" table in `README.md` with links to instructions and walkthrough.

### 6. Submit Pull Request

Test your lab locally, then submit a pull request with:
- Description of the privilege escalation technique
- Any special considerations or dependencies
- Screenshots or examples (optional)

## Resources

- [AWS IAM Privilege Escalation Techniques](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
- [AWS Security Documentation](https://docs.aws.amazon.com/security/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

This project is for educational purposes only. Use responsibly and only in authorized environments.


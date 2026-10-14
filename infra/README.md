# Fix It Lab Repair Cafe Terraform Bootstrap (Increment 1)

This directory contains a small, deployable first infrastructure increment for the Repair Cafe workshop platform.

## What this increment provisions

- **S3 static website bucket** for frontend hosting (requester and volunteer UI)
- **Private S3 uploads bucket** for labels/photos/documents
- **Amazon Cognito** User Pool + web app client
- **API Gateway HTTP API** with `GET /health`
- **AWS Lambda** health-check function wired to API Gateway
- **DynamoDB** table for repair-request records and related entities
- **SNS topic** for email status notifications
- **IAM role/policy** for Lambda with scoped access to required foundational services
- **CloudWatch log groups** for Lambda and API Gateway

## Explicit non-goals in this increment

- Full repair workflow (submission, claiming, notes, status transitions, outcomes)
- Textract orchestration and post-processing logic
- Bedrock prompt/guardrail application logic
- Email templates, retries, or dead-letter handling
- Comprehend integration (disabled by default, optional IAM only)

## Architecture notes and assumptions

1. **S3 website endpoint is HTTP-only**. Amazon S3 static website endpoints do not provide native HTTPS/TLS.
   - Official docs:
     - https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteEndpoints.html
     - https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html
   - **Separate decision required** for HTTPS hosting, typically CloudFront + ACM + Route 53 (or AWS Amplify Hosting).
2. Uploads bucket is private and blocks all public access.
3. Server-side encryption at rest uses SSE-S3 (`AES256`) for both buckets and DynamoDB default encryption.
4. No VPC is used in this increment (intentional for simplicity and lower operational overhead).
5. Bedrock model invocation permission is scoped to the configured foundation model ARN.
6. Comprehend is treated as optional future work (`enable_comprehend = false` by default).
7. SNS email delivery may fail independently; authenticated users must rely on in-app status regardless of email delivery.

## Prerequisites

- Terraform `>= 1.6`
- AWS CLI configured for the target account/role
- Permissions to create IAM, Lambda, API Gateway, Cognito, S3, DynamoDB, SNS, and CloudWatch resources

## Files

- `versions.tf` – Terraform and provider constraints
- `main.tf` – core AWS resources
- `variables.tf` – configurable inputs
- `outputs.tf` – key stack outputs
- `terraform.tfvars.example` – sample non-secret config
- `lambda/health_check.py` – minimal Lambda handler
- `seed/seed_requests.sh` – manual development seed script (outside Terraform state)

## Deployment (manual, no auto-apply)

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
# terraform apply   # run manually when ready
```

> This repository intentionally does **not** run automatic `terraform apply` in CI.

## Validation commands used for this increment

From repository root:

```bash
terraform -chdir=infra fmt -check -recursive
terraform -chdir=infra init -backend=false
terraform -chdir=infra validate
```

## Cost considerations (rough order-of-magnitude)

- S3: storage + requests + data transfer
- API Gateway HTTP API: per-request pricing
- Lambda: request + duration pricing
- DynamoDB On-Demand: read/write request units + storage
- Cognito: monthly active users (free tier may apply)
- SNS email: notification delivery pricing
- CloudWatch Logs: ingestion + retention charges

Actual cost depends on request volume, file sizes, retention, and region.

## Remote state path (documented, not auto-enabled)

Recommended next step:

1. Create a dedicated state bucket (private, versioned, encrypted) and optional DynamoDB state-lock table.
2. Add a `backend.hcl` (not committed with secrets) such as:

```hcl
bucket         = "<terraform-state-bucket>"
key            = "repair-cafe/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
# dynamodb_table = "<terraform-lock-table>"
```

3. Initialize with:

```bash
terraform -chdir=infra init -backend-config=backend.hcl -reconfigure
```

## GitHub OIDC deployment path (documented, no credential assumptions)

Recommended next step for CI deploy workflows:

1. Create an IAM role trusted for GitHub OIDC (`token.actions.githubusercontent.com`).
2. Restrict trust policy by repository and branch/environment conditions.
3. Grant least-privilege permissions for Terraform plan/apply targets.
4. In GitHub Actions, use `aws-actions/configure-aws-credentials` with `role-to-assume`.
5. Keep apply manual (e.g., `workflow_dispatch`, protected environments, required approvals).

Reference docs:
- https://docs.github.com/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
- https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html

## Development test-data seeding (outside Terraform state)

Use the included script to create sample records without modeling sample data in Terraform:

```bash
./seed/seed_requests.sh <table-name> [region]
```

This keeps dev/test data lifecycle separate from infrastructure state.

## Application work still required

Terraform creates foundational infrastructure only. The application still needs to implement:

- Cognito token verification and role/claim mapping for requester vs volunteer permissions
- API endpoints for request submission, listing, claiming, notes, status transitions, outcomes
- Presigned upload URL generation + file metadata persistence
- Textract extraction workflows with confidence display and manual correction pathways
- Bedrock prompt constraints and review UI enforcing volunteer confirmation
- Notification business logic and resilient delivery/error handling
- Audit/event history query patterns in DynamoDB
- Frontend deployment pipeline and static asset publishing

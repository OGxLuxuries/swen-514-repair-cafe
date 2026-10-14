#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <dynamodb-table-name> [aws-region]"
  exit 1
fi

TABLE_NAME="$1"
AWS_REGION="${2:-us-east-1}"

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$TABLE_NAME" \
  --item '{
    "PK": {"S": "REQUEST#demo-001"},
    "SK": {"S": "META#demo-001"},
    "requesterEmail": {"S": "requester@example.com"},
    "itemDescription": {"S": "Vintage mixer with intermittent power"},
    "status": {"S": "submitted"},
    "createdAt": {"S": "2026-01-01T00:00:00Z"}
  }'

echo "Seeded demo request into $TABLE_NAME in $AWS_REGION"

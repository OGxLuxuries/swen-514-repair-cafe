terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Only key/index attributes are declared in Terraform. The application supplies
# other fields when writing items. DynamoDB encrypts these tables at rest by default.
resource "aws_dynamodb_table" "users" {
  name         = "${var.name_prefix}-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user_id"

  # Use the Cognito user's sub as user_id. Store profile and notification details
  # here; passwords and login credentials remain in Cognito.
  attribute {
    name = "user_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "requests" {
  name         = "${var.name_prefix}-requests"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"

  attribute {
    name = "request_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  # Use a consistent UTC ISO 8601 format so string ordering follows time.
  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "requester_id"
    type = "S"
  }

  # Omit volunteer_id on unclaimed requests; do not write an empty string.
  attribute {
    name = "volunteer_id"
    type = "S"
  }

  # Query Submitted for available work, or Completed/Unresolved for history.
  # Category/text filtering requires application logic and pagination; these
  # indexes do not implement full-text search.
  global_secondary_index {
    name            = "status-created-at-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "requester-created-at-index"
    hash_key        = "requester_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "volunteer-created-at-index"
    hash_key        = "volunteer_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  # Index reads are eventually consistent. Claiming must use a conditional write
  # against the base request item to prevent two volunteers claiming it.
  point_in_time_recovery {
    enabled = true
  }
}

resource "aws_dynamodb_table" "records" {
  name         = "${var.name_prefix}-request-records"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "request_id"
  range_key    = "record_key"

  attribute {
    name = "request_id"
    type = "S"
  }

  # Key format: TYPE#<UTC ISO 8601 timestamp>#<unique ID>.
  # TYPE is NOTE, HISTORY, FILE, or AI. Query by request_id and optionally use
  # begins_with(record_key, "NOTE#") to retrieve one record type.
  # Items hold note authors/text, outcome/confirmation history, S3 object keys,
  # or AI service/results/confidence/review status as appropriate.
  attribute {
    name = "record_key"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }
}

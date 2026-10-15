output "table_names" {
  description = "DynamoDB table names for backend configuration and sample-data setup."
  value = {
    users    = aws_dynamodb_table.users.name
    requests = aws_dynamodb_table.requests.name
    records  = aws_dynamodb_table.records.name
  }
}

output "table_arns" {
  description = "DynamoDB table ARNs for Lambda access permissions."
  value = {
    users    = aws_dynamodb_table.users.arn
    requests = aws_dynamodb_table.requests.arn
    records  = aws_dynamodb_table.records.arn
  }
}

output "request_index_names" {
  description = "Request indexes for status, requester, and volunteer queries."
  value = {
    status    = "status-created-at-index"
    requester = "requester-created-at-index"
    volunteer = "volunteer-created-at-index"
  }
}

output "request_index_arns" {
  description = "Request index ARNs for Lambda query permissions."
  value = [
    for index in aws_dynamodb_table.requests.global_secondary_index :
    "${aws_dynamodb_table.requests.arn}/index/${index.name}"
  ]
}

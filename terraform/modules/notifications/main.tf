terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_sns_topic" "repair_status" {
  name         = "${var.name_prefix}-repair-status"
  display_name = "Repair Cafe Status Updates"
  fifo_topic   = false
}

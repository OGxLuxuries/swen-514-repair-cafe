import json
import os
from datetime import datetime, timezone


def handler(event, context):
    body = {
        "status": "ok",
        "service": "fixit-lab-repair-api",
        "environment": os.getenv("ENVIRONMENT", "unknown"),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "requestId": getattr(context, "aws_request_id", None),
        "path": event.get("rawPath") if isinstance(event, dict) else None,
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }

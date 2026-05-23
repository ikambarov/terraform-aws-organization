import json
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError


config = boto3.client("config")
s3 = boto3.client("s3")


def _annotation(message):
    return message[:256]


def _bucket_compliance(bucket_name, required_key, allowed_values):
    try:
        response = s3.get_bucket_tagging(Bucket=bucket_name)
        tags = {tag["Key"]: tag["Value"] for tag in response.get("TagSet", [])}
    except ClientError as error:
        code = error.response.get("Error", {}).get("Code")
        if code in ("NoSuchTagSet", "NoSuchBucket"):
            tags = {}
        else:
            raise

    value = tags.get(required_key)
    if value is None:
        return "NON_COMPLIANT", _annotation(f"Missing required S3 bucket tag {required_key}.")
    if value not in allowed_values:
        return "NON_COMPLIANT", _annotation(
            f"S3 bucket tag {required_key} has unsupported value {value}."
        )
    return "COMPLIANT", _annotation(f"S3 bucket tag {required_key} is set to {value}.")


def _evaluation(bucket_name, required_key, allowed_values, timestamp):
    compliance_type, annotation = _bucket_compliance(bucket_name, required_key, allowed_values)
    return {
        "ComplianceResourceType": "AWS::S3::Bucket",
        "ComplianceResourceId": bucket_name,
        "ComplianceType": compliance_type,
        "Annotation": annotation,
        "OrderingTimestamp": timestamp,
    }


def lambda_handler(event, context):
    rule_parameters = json.loads(event.get("ruleParameters", "{}"))
    required_key = rule_parameters["tagKey"]
    allowed_values = set(rule_parameters["allowedValues"])
    result_token = event.get("resultToken", "TESTMODE")
    timestamp = datetime.now(timezone.utc)

    invoking_event = json.loads(event.get("invokingEvent", "{}"))
    message_type = invoking_event.get("messageType")
    evaluations = []

    if message_type == "ConfigurationItemChangeNotification":
        item = invoking_event.get("configurationItem", {})
        if item.get("resourceType") == "AWS::S3::Bucket":
            evaluations.append(
                _evaluation(item["resourceId"], required_key, allowed_values, timestamp)
            )
    else:
        for bucket in s3.list_buckets().get("Buckets", []):
            evaluations.append(
                _evaluation(bucket["Name"], required_key, allowed_values, timestamp)
            )

    for start in range(0, len(evaluations), 100):
        config.put_evaluations(
            Evaluations=evaluations[start : start + 100],
            ResultToken=result_token,
        )

    return {"evaluations": len(evaluations)}

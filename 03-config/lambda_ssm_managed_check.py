import json
from datetime import datetime, timezone

import boto3


config = boto3.client("config")
ec2 = boto3.client("ec2")
ssm = boto3.client("ssm")


def _annotation(message):
    return message[:256]


def _tag_value(tags, key):
    for tag in tags or []:
        if tag.get("Key") == key:
            return tag.get("Value")
    return None


def _enabled_instances(tag_key, tag_value):
    paginator = ec2.get_paginator("describe_instances")
    for page in paginator.paginate(
        Filters=[
            {"Name": f"tag:{tag_key}", "Values": [tag_value]},
            {
                "Name": "instance-state-name",
                "Values": ["pending", "running", "stopping", "stopped"],
            },
        ]
    ):
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                yield instance["InstanceId"]


def _managed_instance_ids():
    managed = set()
    paginator = ssm.get_paginator("describe_instance_information")
    for page in paginator.paginate():
        for instance in page.get("InstanceInformationList", []):
            managed.add(instance["InstanceId"])
    return managed


def _evaluation(instance_id, managed_ids, timestamp):
    if instance_id in managed_ids:
        compliance_type = "COMPLIANT"
        annotation = "Instance is managed by SSM."
    else:
        compliance_type = "NON_COMPLIANT"
        annotation = "Instance has SSMManaged enabled but is not managed by SSM."

    return {
        "ComplianceResourceType": "AWS::EC2::Instance",
        "ComplianceResourceId": instance_id,
        "ComplianceType": compliance_type,
        "Annotation": _annotation(annotation),
        "OrderingTimestamp": timestamp,
    }


def lambda_handler(event, context):
    rule_parameters = json.loads(event.get("ruleParameters", "{}"))
    tag_key = rule_parameters["tagKey"]
    tag_value = rule_parameters["tagValue"]
    result_token = event.get("resultToken", "TESTMODE")
    timestamp = datetime.now(timezone.utc)

    invoking_event = json.loads(event.get("invokingEvent", "{}"))
    configuration_item = invoking_event.get("configurationItem", {})
    managed_ids = _managed_instance_ids()
    evaluations = []

    if configuration_item.get("resourceType") == "AWS::EC2::Instance":
        instance_id = configuration_item["resourceId"]
        if _tag_value(configuration_item.get("tags"), tag_key) == tag_value:
            evaluations.append(_evaluation(instance_id, managed_ids, timestamp))
    else:
        for instance_id in _enabled_instances(tag_key, tag_value):
            evaluations.append(_evaluation(instance_id, managed_ids, timestamp))

    for start in range(0, len(evaluations), 100):
        config.put_evaluations(
            Evaluations=evaluations[start : start + 100],
            ResultToken=result_token,
        )

    return {"evaluations": len(evaluations)}

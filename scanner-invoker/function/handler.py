import boto3
import json
import datetime
import os
import subprocess
import uuid

def handler(event, context):
    """
    Lambda entry point for a Cloudmapper scan invocation.
    The input event should look like this:
    {
        "region": "us-west-2",
        "account_id": <target AWS account ID>,
        "credentials_secret_id": <sec-mgt secret ID containing JSON AWS creds - optional>
        "credentials": <raw JSON AWS creds - optional>
    }

    All options above are mandatory.

    The SQS queue to send scanner items to is defined via the $SCANNER_QUEUE environment variable.
    """
    sqs = boto3.client('sqs')
    sts = boto3.client('sts')
    ssm = boto3.client('ssm')

    caller_identity = sts.get_caller_identity()

    scanner_queue_url = os.environ['SCANNER_QUEUE_URL']
    scan_id = str(uuid.uuid4())

    created = datetime.datetime.now().isoformat()
    credentials_parameter_name = None

    if event.get('credentials'):
        # if raw credentials were supplied, we put these into a KMS-encrypted SSM parameter
        # and pass the parameter name to the scanner

        if event.get('credentials_secret_id'):
            raise ValueError('cannot specify credentials and credentials_secret_id')

        credentials_parameter_name = '/cloudmapper/{}'.format(scan_id)
        ssm.put_parameter(
            Name=credentials_parameter_name,
            Value=json.dumps(event.get('credentials')),
            Type='SecureString',
            # no KMS Key ID: use default SSM KMS key for the account
        )

    sqs.send_message(
        QueueUrl=scanner_queue_url,
        MessageBody=json.dumps({
            'scan_id':      scan_id,
            'account_id':   event['account_id'],
            'created':      created,
            'region':       event['region'],
            'credentials_secret_id': event.get('credentials_secret_id', None),
            'credentials_parameter_name': credentials_parameter_name,
        }),
    )

    # let the caller know some crucial details about the scan
    return {
        'scan_id': scan_id,
        'created': created,
        'region': event['region'],
    }

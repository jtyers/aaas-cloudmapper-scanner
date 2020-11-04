import boto3
import datetime
import glob
import json
import os
import os.path
import subprocess
import random
import time

report_dir = "/tmp/scan-report"

# these vars are templated in by Terraform
queue_url = os.environ["QUEUE_URL"]
bucket_name = os.environ["BUCKET_NAME"]
random_wait = os.environ["RANDOM_WAIT"]

max_messages = 3
max_wait_time = 20
dirname = os.path.dirname(os.path.abspath(__file__))

"""
Script for individual `cloudmapper collect` jobs.


"""

# RANDOM_WAIT can be used to specify a random wait (in ms) up to a configured amount
wait = os.environ.get('RANDOM_WAIT', None)
if wait is not None and wait != "":
    random.seed()
    wait_ms = random.randint(500, int(wait))

    print('Sleeping for', wait_ms, 'ms')
    time.sleep(wait_ms/1000)  # convert ms to s

sts = boto3.client('sts')
ssm = boto3.client('ssm')
sqs = boto3.client('sqs')
secretsmanager = boto3.client('secretsmanager')
s3 = boto3.client('s3')


caller_identity = sts.get_caller_identity()

# receive a max of 3 messages, with a 5-minute timeout; and after that turn off
# the instance (so the ASG scales down again); SQS messages should look like Prowler scans:
#  {
#      "scan_id": <scan ID>,
#      "account_id": <target aws account ID>,
#      "region": "us-west-2",
#      "created": <created timestamp in ISO8601 fmt>,
#  }
#  
response = sqs.receive_message(
  QueueUrl=queue_url,
  MaxNumberOfMessages=max_messages,
  WaitTimeSeconds=max_wait_time,
)

for message in response.get('Messages', []):
    print('message', message['Body'])
    body = json.loads(message['Body'])

    created = datetime.datetime.fromisoformat(body['created'])

    credentials_secret_id = body.get("credentials_secret_id", None)
    credentials_parameter_name = body.get("credentials_parameter_name", None)
    env = None

    err_extra = ' (no creds supplied)'

    if credentials_secret_id or credentials_parameter_name:
        credentials = None

        if credentials_secret_id:
            response = secretsmanager.get_secret_value(SecretId=credentials_secret_id)
            credentials = json.loads(response['SecretString'])
            err_extra = ' (using credentials_secret_id {})'.format(credentials_secret_id)

        elif credentials_parameter_name:
            # load the parameter from SSM
            parameters = ssm.get_parameters(
                Names=[ credentials_parameter_name ],
                WithDecryption=True
            )

            if len(parameters['Parameters']) != 1:
                raise ValueError('error loading parameter', credentials_parameter_name)

            credentials = json.loads(parameters['Parameters'][0]['Value'])
            err_extra = ' (using credentials_parameter_name {})'.format(credentials_parameter_name)


        # credentials should now look like:
        # {
        #   "AccessKeyId": ...
        #   "SecretAccessKey": ...
        #   "SessionToken": ...
        #   "Expiration": ...
        # }

        # validate that we are in the correct account using those creds
        this_sts = boto3.client('sts',
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken'],
        )
        this_caller_identity = this_sts.get_caller_identity()

        if body['account_id'] != this_caller_identity['Account']:
            raise ValueError('mismatched account IDs {}, wanted {}, got {}'.format(
                err_extra, body['account_id'], this_caller_identity['Account']))

        # now set up the env and roll on!
        env = {
            **os.environ,
            'AWS_ACCESS_KEY_ID': credentials['AccessKeyId'],
            'AWS_SECRET_ACCESS_KEY': credentials['SecretAccessKey'],
            'AWS_SESSION_TOKEN': credentials['SessionToken'],
            'AWS_SESSION_EXPIRATION': credentials['Expiration'],
        }
        print('Loaded credentials', err_extra, 'expiring', credentials['Expiration'])

    else:
        if body['account_id'] != caller_identity['Account']:
            raise ValueError('mismatched account IDs, wanted {}, got {}'.format(
                body['account_id'], caller_identity['Account']))


    print('About to run cloudmapper collect',
          'against account', body['account_id'], 'in', body['region'])

    subprocess.run(
        [
            os.path.join(dirname, 'scan.sh'),
            '--account', body['account_id'],
            '--region', body['region'],
        ],
        env=env,
        check=True,
#        stdout=subprocess.PIPE,
#        stderr=subprocess.PIPE,
    )

    # scan.sh should save account data to /tmp/scan-report/scan-report.tgz
    report_archive_path = '/tmp/scan-report/scan-report.tgz'

    key = "results/{account_id}/{year}/{month}/{day}/{hour}/{scan_id}.tgz".format(
        account_id=body['account_id'],
        year=created.year,
        month=created.month,
        day=created.day,
        hour=created.hour,
        scan_id=body['scan_id'],
    )

    with open(report_archive_path, 'rb') as report_archive:
        s3.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=report_archive,
        )

    os.unlink(report_archive_path)  # delete so next loop run cannot pick it up mistakenly
    sqs.delete_message(
        QueueUrl=queue_url,
        ReceiptHandle=message['ReceiptHandle'],
    )

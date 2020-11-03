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

def handler(event, context):
    """
    Lambda entry point for an individual Prowler check.

    The input event will come from SQS; the message payload should look like:
    {
        "scan_id": <scan ID>,
        "check_id": <prowler check ID, e.g. check11>,
        "account_id": <target aws account ID>,
        "region": "us-west-2",
        "created": <created timestamp in ISO8601 fmt>,
    }

    """

    # RANDOM_WAIT can be used to specify a random wait (in ms) up to a configured amount
    wait = os.environ.get('RANDOM_WAIT', None)
    if wait is not None:
        random.seed()
        wait_ms = random.randint(500, int(wait))

        print('Sleeping for', wait_ms, 'ms')
        time.sleep(wait_ms/1000)  # convert ms to s

    sts = boto3.client('sts')
    ssm = boto3.client('ssm')
    secretsmanager = boto3.client('secretsmanager')

    caller_identity = sts.get_caller_identity()

    for record in event['Records']:
        body = json.loads(record['body'])

        check_id = body["check_id"]
        bucket_name = os.environ["BUCKET_NAME"]
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


        print('About to run prowler for check_id', check_id,
              'against account', body['account_id'], 'in', body['region'])

        p = subprocess.run([
            './scan.sh',
            '--account', body['account_id'],
            '--check', check_id,
            '--region', body['region'],
        ], env=env)

        p.check_returncode()

        # if we get here, the process ran successfully
        s3 = boto3.client('s3')

        for f in glob.iglob(report_dir + "/*"):
            key = "results/{account_id}/{year}/{month}/{day}/{hour}/prowler-{scan_id}/{check_id}.json".format(
                account_id=body['account_id'],
                year=created.year,
                month=created.month,
                day=created.day,
                hour=created.hour,
                scan_id=body['scan_id'],
                check_id=check_id,
            )
            with open(f, 'rb') as ff:
                s3.put_object(
                    Bucket=bucket_name,
                    Key=key,
                    Body=ff,
                )

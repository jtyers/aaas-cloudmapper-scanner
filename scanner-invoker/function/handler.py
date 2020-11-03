import boto3
import json
import datetime
import os
import subprocess
import uuid

# list of checks pulled fomr prowler; to generate this list in an extracted Prowler source dir:
#   grep -H GROUP_CHECKS prowler/groups/* | sed "s/^\(.*\):.*='\(.*\)'$/\1 \2/" | jq -Rsr 'split("\n")|map(split(" ")|{name: .[0], checks: .[1] }) | map(select(.name != null)) | map({name: .name|sub("^prowler\/groups\/"; ""), checks: .checks|split(",")})'
CHECKS = {
    'iam': {
    "name": "group1_iam",
    "checks": [
      "check11", "check12", "check13", "check14", "check15", "check16", "check17", "check18", "check19", "check110", "check111",
      "check112", "check113", "check114", "check115", "check116", "check117", "check118", "check119", "check120", "check121", 
        "check122", "extra774"
    ]
  },
    'logging': {
    "name": "group2_logging",
    "checks": [ "check21", "check22", "check23", "check24", "check25", "check26", "check27", "check28", "check29" ]
  },
    'monitoring': {
    "name": "group3_monitoring",
    "checks": [
      "check31", "check32", "check33", "check34", "check35", "check36", "check37", "check38",
      "check39", "check310", "check311", "check312", "check313", "check314"
    ]
  },
    'networking': {
    "name": "group4_networking",
    "checks": [ "check41", "check42", "check43", "check44" ]
  },
  'cislevel1': {
    "name": "group5_cislevel1",
    "checks": [
      "check11", "check12", "check13", "check14", "check15", "check16", "check17", "check18", "check19",
      "check110", "check111", "check112", "check113", "check115", "check116", "check117", "check118",
      "check119", "check120", "check122", "check21", "check23", "check24", "check25", "check26", "check31",
      "check32", "check33", "check34", "check35", "check38", "check312", "check313", "check314", "check41", "check42"
    ]
  },
  'cislevel2': {
    "name": "group6_cislevel2",
    "checks": [
      "check11", "check12", "check13", "check14", "check15", "check16", "check17", "check18", "check19",
      "check110", "check111", "check112", "check113", "check114", "check115", "check116", "check117", "check118",
      "check119", "check120", "check121", "check122", "check21", "check22", "check23", "check24", "check25",
      "check26", "check27", "check28", "check29", "check31", "check32", "check33", "check34", "check35", "check36",
      "check37", "check38", "check39", "check310", "check311", "check312", "check313", "check314", "check41", "check42",
      "check43", "check44"
    ]
  },
  "extras": {
    "name": "group7_extras",
    "checks": [
      "extra71", "extra72", "extra73", "extra74", "extra75", "extra76", "extra77", "extra78", "extra79",
      "extra710", "extra711", "extra712", "extra713", "extra714", "extra715", "extra716", "extra717",
      "extra718", "extra719", "extra720", "extra721", "extra722", "extra723", "extra724", "extra725",
      "extra726", "extra727", "extra728", "extra729", "extra730", "extra731", "extra732", "extra733",
      "extra734", "extra735", "extra736", "extra737", "extra738", "extra739", "extra740", "extra741",
      "extra742", "extra743", "extra744", "extra745", "extra746", "extra747", "extra748", "extra749",
      "extra750", "extra751", "extra752", "extra753", "extra754", "extra755", "extra756", "extra757",
      "extra758", "extra761", "extra762", "extra763", "extra764", "extra765", "extra767", "extra768",
      "extra769", "extra770", "extra771", "extra772", "extra773", "extra774", "extra775", "extra776",
      "extra777", "extra778", "extra779", "extra780", "extra781", "extra782", "extra783", "extra784",
      "extra785", "extra786", "extra787", "extra788", "extra791", "extra792", "extra793", "extra794",
      "extra795", "extra796", "extra797", "extra798", "extra799", "extra7100", "extra7101"
    ]
  },
  'forensics': {
    "name": "group8_forensics",
    "checks": [
      "check21", "check22", "check23", "check24", "check25", "check26", "check27", "check29", "extra712",
      "extra713", "extra714", "extra715", "extra717", "extra718", "extra719", "extra720", "extra721", "extra722",
      "extra725", "extra7101"
    ]
  },
  'gdpr': {
    "name": "group9_gdpr",
    "checks": [
      "extra718", "extra725", "extra727", "check12", "check113", "check114", "extra71", "extra731", "extra732",
      "extra733", "check25", "check39", "check21", "check22", "check23", "check24", "check26", "check27", "check35",
      "extra726", "extra714", "extra715", "extra717", "extra719", "extra720", "extra721", "extra722", "check43",
      "check25", "extra714", "extra729", "extra734", "extra735", "extra736", "extra738", "extra740", "extra761",
      "check11", "check110", "check111", "check112", "check116", "check120", "check122", "check13", "check14",
      "check15", "check16", "check17", "check18", "check19", "check28", "check29", "check31", "check310", "check311",
      "check312", "check313", "check314", "check32", "check33", "check34", "check36", "check37", "check38", "check41",
      "check42", "extra711", "extra72", "extra723", "extra730", "extra739", "extra76", "extra763", "extra778", "extra78",
      "extra792"
    ]
  },
  'hipaa': {
    "name": "group10_hipaa",
    "checks": [ "check12", "check113", "check23", "check26", "check27", "check29", "extra718", "extra725",
      "extra72", "extra75", "extra717", "extra729", "extra734", "check38", "extra73", "extra740", "extra735",
      "check112", "check13", "check15", "check16", "check17", "check18", "check19", "check21", "check24",
      "check28", "check31", "check310", "check311", "check312", "check313", "check314", "check32", "check33",
      "check34", "check35", "check36", "check37", "check39", "extra792"
    ]
  },
  'secrets': {
    "name": "group11_secrets",
    "checks": [ "extra741", "extra742", "extra759", "extra760", "extra768", "extra775" ]
  },
  'apigateway': {
    "name": "group12_apigateway",
    "checks": [ "extra722", "extra743", "extra744", "extra745", "extra746" ]
  },
  'rds': {
    "name": "group13_rds",
    "checks": [ "extra78", "extra723", "extra735", "extra739", "extra747" ]
  },
  'elasticsearch': {
    "name": "group14_elasticsearch",
    "checks": [
      "extra715", "extra716", "extra779", "extra780", "extra781", "extra782",
      "extra783", "extra784", "extra785", "extra787", "extra788", "extra7101"
    ]
  },
  'pci': {
    "name": "group15_pci",
    "checks": [
      "check11", "check12", "check13", "check14", "check15", "check16", "check17", "check18", "check19",
      "check110", "check112", "check113", "check114", "check116", "check21", "check23", "check25", "check26",
      "check27", "check28", "check29", "check314", "check36", "check38", "check43", "extra713", "extra717",
      "extra718", "extra72", "extra729", "extra735", "extra738", "extra740", "extra744", "extra748", "extra75",
      "extra750", "extra751", "extra753", "extra754", "extra755", "extra756", "extra773", "extra78", "extra780",
      "extra781", "extra782", "extra783", "extra784", "extra785", "extra787", "extra788"
    ]
  },
  'trustboundaries': {
    "name": "group16_trustboundaries",
    "checks": [ "extra789", "extra790" ]
  },
  'internetexposed': {
    "name": "group17_internetexposed",
    "checks": [
      "check41", "check42", "extra72", "extra73", "extra74", "extra76", "extra77", "extra78", "extra79",
      "extra710", "extra711", "extra716", "extra723", "extra727", "extra731", "extra736", "extra738", "extra745",
      "extra748", "extra749", "extra750", "extra751", "extra752", "extra753", "extra754", "extra755", "extra756",
      "extra770", "extra771", "extra778", "extra779", "extra787", "extra788", "extra798"
    ]
  },
  'iso27001': {
    "name": "group18_iso27001",
    "checks": [
      "check11", "check110", "check111", "check112", "check113", "check116", "check12", "check122", "check13",
      "check14", "check15", "check16", "check17", "check18", "check19", "check21", "check23", "check24", "check25",
      "check26", "check29", "check31", "check310", "check311", "check312", "check313", "check314", "check32", "check33",
      "check34", "check35", "check36", "check37", "check38", "check39", "check41", "check42", "check43", "extra711",
      "extra72", "extra723", "extra731", "extra735", "extra76", "extra78", "extra792"
    ]
  },
  'eks-cis': {
    "name": "group19_eks-cis",
    "checks": [
      "extra765", "extra794", "extra795", "extra796", "extra797"
    ]
  },
}

def handler(event, context):
    """
    Lambda entry point for a Prowler scan invocation. This lambda works out what checks
    are needed to complete the scan, and queues each on the specified SQS queue, to be picked
    up by the scanner-scanner lambda.

    The input event should look like this:
    {
        "group": "cislevel2",
        "region": "us-west-2",
        "account_id": <target AWS account ID>,
        "credentials_secret_id": <sec-mgt secret ID containing JSON AWS creds - optional>
        "credentials": <raw JSON AWS creds - optional>
    }

    We expect that the target AWS account ID matches the Lambda execution role; the account_id
    is merely there as a sanity check to ensure we're assuming the right role in the right account.

    All options above are mandatory.

    The SQS queue to send scanner items to is defined via the $SCANNER_QUEUE environment variable.
    """
    sqs = boto3.client('sqs')
    sts = boto3.client('sts')
    ssm = boto3.client('ssm')

    caller_identity = sts.get_caller_identity()

    group_checks = CHECKS[event['group']]
    checks = group_checks['checks']

    scanner_queue_url = os.environ['SCANNER_QUEUE_URL']
    scan_id = str(uuid.uuid4())

    created = datetime.datetime.now().isoformat()
    credentials_parameter_name = None

    if event.get('credentials'):
        # if raw credentials were supplied, we put these into a KMS-encrypted SSM parameter
        # and pass the parameter name to the scanner

        if event.get('credentials_secret_id'):
            raise ValueError('cannot specify credentials and credentials_secret_id')

        credentials_parameter_name = '/prowler-scanner/{}'.format(scan_id)
        ssm.put_parameter(
            Name=credentials_parameter_name,
            Value=json.dumps(event.get('credentials')),
            Type='SecureString',
            # no KMS Key ID: use default SSM KMS key for the account
        )

    for check in checks:
        sqs.send_message(
            QueueUrl=scanner_queue_url,
            MessageBody=json.dumps({
                'scan_id':      scan_id,
                'check_id':     check,
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

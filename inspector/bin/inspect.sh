#!/bin/bash
set -eu

account="${ACCOUNT_ID}"

c="python3 cloudmapper.py"
echo "configuring cloudmapper for account $account"
$c configure add-account --id $account --name $account

$c prepare --account $account
$c weboftrust --accounts $account

$c report --accounts $account
$c iam_report --accounts $account

$c audit --accounts $account --json > web/account-data/audit.json || true
$c find_admins  --accounts $account --json > web/account-data/find_admins.json || true
$c find_unused  --accounts $account > web/account-data/find_unused.json || true
$c public       --accounts $account > web/account-data/public.json || true

jq -s 'map(.Volumes|map(select(.Encrypted == false)))|flatten' account-data/*/*/ec2-describe-volumes.json \
  > web/account-data/unencrypted-ebs-volumes.json

python3 cloudmapper.py webserver --public >/dev/null &
pid=$!

if [ $# -gt 0 ]; then
  "$@"
else
  echo "dropping into shell"
  bash -il
fi

kill $pid

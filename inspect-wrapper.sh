#!/bin/sh

set -eu

bucket="aaas-test-cloudmapper-results"
extractDir="$PWD/account-data"
selector="fzy"

choices=$( aws s3 ls "s3://$bucket/results/" )
chosenAccount=$(
    awk '{print $2}' <<<"$choices" \
    | $selector --prompt="Choose account: " \
    | sed -e 's|/$||'
)

choices=$(aws s3 ls --recursive "s3://aaas-test-cloudmapper-results/results/${chosenAccount}/")
chosenScan=$(
    awk '{print $4}' <<<"$choices" \
    | $selector --prompt="Choose scan: "
)

aws s3 cp "s3://$bucket/$chosenScan" ./scan.tgz

[ -d "$extractDir" ] && rm -r "$extractDir"
mkdir "$extractDir"
tar -xzf ./scan.tgz -C "$extractDir"

docker run --rm -it \
  -v "$extractDir":/opt/cloudmapper/account-data \
  -p 8000:8000 \
  -e ACCOUNT_ID="$chosenAccount" \
  cloudmapper-scanner-inspector


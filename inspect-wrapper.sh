#!/bin/sh

set -eu

onExit() {
  rm -rf "$extractDir" $scanFile
}

bucket="aaas-test-cloudmapper-results"
extractDir="$(mktemp -d)"
selector="fzy"
scanFile="scan.tgz"
scanFileUpdated="scan-updated.tgz"

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

aws s3 cp "s3://$bucket/$chosenScan" $scanFile

[ -d "$extractDir" ] && rm -r "$extractDir"
mkdir "$extractDir"
tar -xzf $scanFile -C "$extractDir"

docker run --rm -it \
  --name cloudmapper-scanner-inspector \
  -v "$extractDir/account-data":/opt/cloudmapper/account-data \
  -v "$extractDir/web":/opt/cloudmapper/web \
  -p 8000:8000 \
  -e ACCOUNT_ID="$chosenAccount" \
  "$@" \
  cloudmapper-scanner-inspector

tar czf $scanFileUpdated -C $extractDir account-data web

if [ "$(md5sum $scanFile)" != "$(md5sum $scanFileUpdated)" ]; then
  echo "data was changed, updating s3" >&2
  aws s3 cp $scanFileUpdated "s3://$bucket/$chosenScan" 
fi

trap onExit err exit

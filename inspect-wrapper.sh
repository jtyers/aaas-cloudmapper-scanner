#!/bin/sh

USAGE="$(basename $0) -i|--interactive | --scan <scan id> --account <account id>"

set -eu

onExit() {
  stopContainer &>/dev/null || true
  rm -rf "$extractDir" $scanFile $scanFileUpdated || true
}

warn() {
	echo -e "$@" >&2
}

die() {
	warn "$@"
	exit 1
}

extractScan() {
  aws s3 cp "s3://$bucket/$chosenScan" $scanFile

  [ -d "$extractDir" ] && rm -r "$extractDir"
  mkdir "$extractDir"
  tar -xzf $scanFile -C "$extractDir"

}

runContainer() {
  docker run --rm -i \
    --name cloudmapper-scanner-inspector \
    -v "$extractDir/account-data":/opt/cloudmapper/account-data \
    -v "$extractDir/web":/opt/cloudmapper/web \
    -p 8000:8000 \
    -e ACCOUNT_ID="$chosenAccount" \
    cloudmapper-scanner-inspector \
    "$@"
}

stopContainer() {
  docker stop cloudmapper-scanner-inspector "$@"
}

bucket="aaas-test-cloudmapper-results"
extractDir="$(mktemp -d)"
selector="fzy"
scanFile="scan.tgz"
scanFileUpdated="scan-updated.tgz"

# saveDataTo: printf fmt string, called with <account id> <scamn id>; only used for
#  non-interactive mode
saveDataTo="$HOME/GoogleDrive-encrypted/BristolCyberSecurity/Projects/NBS AWS Audit 2020/scan-results/%s/%s"

interactive=0
chosenAccount=""
chosenScan=""

O=`getopt -n scan.sh -l interactive,account:,scan: -- ia:s: "$@"` || die "$usage"
eval set -- "$O"
while true; do
    case "$1" in
    -i|--interactive)	  interactive=1; shift;;
    -a|--account)	  chosenAccount=$2; shift; shift;;
    -s|--scan)	    chosenScan=$2; shift; shift;;
    --)			        shift; break;;
    *)			        die "$usage";;
    esac
done

[ $# -eq 0 ] || die "$USAGE"

if [ $interactive -eq 0 ]; then
  [ -n "$chosenAccount" ] || die "must speciy --account"
  [ -n "$chosenScan" ] || die "must speciy --scan"

  echo "inspect-wrapper: $chosenAccount $chosenScan" >&2
 
  scanId="$chosenScan"  # hold onto original scan ID
  chosenScan=$(
    aws s3 ls --recursive "s3://aaas-test-cloudmapper-results/results/${chosenAccount}/" \
    | awk "/${chosenScan}/{ print \$4 }"
  )

  extractScan
  runContainer true  # run 'true' just to cause it to exit

  saveDataToDir=$(printf "$saveDataTo" "$chosenAccount" "$scanId")
  mkdir -p "$saveDataToDir"
  cp -r $extractDir/web/account-data "$saveDataToDir"

  # we only save web/account-data (account-data is just json blobs)

else
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

  extractScan
  runContainer

  tar czf $scanFileUpdated -C $extractDir account-data web

  if [ "$(md5sum $scanFile)" != "$(md5sum $scanFileUpdated)" ]; then
    echo "data was changed, updating s3" >&2
    aws s3 cp $scanFileUpdated "s3://$bucket/$chosenScan" 
  fi

fi

trap onExit err exit

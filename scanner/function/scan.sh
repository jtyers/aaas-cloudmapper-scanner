#!/bin/bash

USAGE="scan.sh --account <account id> --region <region>"
#
# Invoke `cloudmapper collect` and place the results (content of ./account-data) in /tmp/scan-report.tgz.
#

set -eu

warn() {
	echo -e "$@" >&2
}

die() {
	warn "$@"
	exit 1
}

account=""
region=""

O=`getopt -n scan.sh -l account:,region: -- a:r: "$@"` || die "$usage"
eval set -- "$O"
while true; do
    case "$1" in
    -a|--account)	  account=$2; shift; shift;;
    -r|--region)	  region=$2; shift; shift;;
    --)			        shift; break;;
    *)			        die "$usage";;
    esac
done

[ $# -eq 0 ] || die "$USAGE"
[ -n "$account" ] || die "must speciy --account"
[ -n "$region" ] || die "must speciy --region"

reportDir="/tmp/scan-report"
mkdir -p $reportDir
	
# install cloudmapper
cloudmapperDir="/opt/cloudmapper"
[ -d "$cloudmapperDir" ] || \
  git clone --depth=1 https://github.com/duo-labs/cloudmapper.git "$cloudmapperDir"


cd "$cloudmapperDir"  # hardcoded cloudmapper install location
#cd ~/github/cloudmapper  # hardcoded cloudmapper install location

# ensure we start with no config
configFile="config.json"
rm -f $configFile

python3 cloudmapper.py configure \
  add-account \
  --config-file $configFile \
  --name $account \
  --id $account

python3 cloudmapper.py collect \
  --regions $region \
  --account $account \
  || true
  # allow failures so errors are picked up

tar czf $reportDir/scan-report.tgz -C account-data .

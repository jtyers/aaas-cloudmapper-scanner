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

export PATH=$PATH:/opt/bin:/opt/prowler:/opt/python/bin:$(dirname $0)/prowler

mkdir -p $reportDir

#cd /opt/cloudmapper  # hardcoded cloudmapper install location
cd ~/github/cloudmapper  # hardcoded cloudmapper install location

# ensure we start with no config
configFile="config.json"
rm -f $configFile

python cloudmapper.py configure \
  add-account \
  --config-file $configFile \
  --name $account \
  --id $account

python cloudmapper.py collect \
  --regions $region \
  --account $account

tar czf $reportDir/scan-report.tgz -C account-data .

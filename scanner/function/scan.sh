#!/bin/bash

USAGE="scan.sh --account <account id> --region <region>"
#
# Invoke `cloudmapper collect` and place the results (content of ./account-data) in /tmp/scan-report.tgz.
#

set -eux
set -o pipefail

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

c="python3 cloudmapper.py"

$c configure \
  add-account \
  --config-file $configFile \
  --name $account \
  --id $account

$c collect \
  --regions $region \
  --account $account \
  || true  # allow failures so errors are picked up

# # run various reporting tools here too
# # FIXME: sg_ips currently isn't here as we need to sort out missing deps, MaxMind GeoLite data etc
# 
# # this requires GBs-worth of data on public AMIs, so don't bother
# #$c amis         --accounts $account
# 
# $c audit        --accounts $account --json > web/account-data/audit.json || true
# $c find_admins  --accounts $account --json > web/account-data/find_admins.json || true
# $c find_unused  --accounts $account --json > web/account-data/find_unused.json || true
# $c public       --accounts $account --json > web/account-data/public.json || true
# 
# # report: saves to web/account-data/report.html
# $c report \
#   --accounts $account \
#   || true  # allow failures so errors are picked up
# 
# # iam_report: saves to web/account-data/iam_report.html
# $c iam_report   --accounts $account || true  # allow failures so errors are picked up

# tar up both account-data and web folders (web can be served from S3)
tar czf $reportDir/scan-report.tgz account-data web

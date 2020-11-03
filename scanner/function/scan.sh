#!/bin/bash

USAGE="scan.sh --account <account id> --check <check_id> --region <region>"
#
# Invoke Prowler and place the results in /tmp/scan-report for other scripts to
# pick up. After the script has run, /tmp/scan-report will contain:
#   /tmp/scan-report/<accountId>.raw.json
#   /tmp/scan-report/<accountId>.json
#   /tmp/scan-report/<accountId>.csv
#

set -eu

warn() {
	echo -e "$@" >&2
}

die() {
	warn "$@"
	exit 1
}

check=""
account=""
region=""

O=`getopt -n scan.sh -l account:,check:,region: -- a:c:r: "$@"` || die "$usage"
eval set -- "$O"
while true; do
    case "$1" in
    -a|--account)	  account=$2; shift; shift;;
    -c|--check)	    check=$2; shift; shift;;
    -r|--region)	  region=$2; shift; shift;;
    --)			        shift; break;;
    *)			        die "$usage";;
    esac
done

[ $# -eq 0 ] || die "$USAGE"
[ -n "$account" ] || die "must speciy --account"
[ -n "$check" ] || die "must speciy --check"
[ -n "$region" ] || die "must speciy --region"

reportDir="/tmp/scan-report"

export PATH=$PATH:/opt/bin:/opt/prowler:/opt/python/bin:$(dirname $0)/prowler

mkdir -p $reportDir

prowlerArgs="-c $check -f $region -r $region"

# Text / HTML reporting mode
#prowler -r "$SCAN_REGION" -f "$SCAN_REGION" $prowlerArgs \
#  | tee $reportDir/output.txt \
#  | ansi2html -la \
#  > $reportDir/report.html

# Though prowler supports direct CSV output we pipe the json into
# a csv converter, to ensure the formats are 100% equivalent

# Also, only run if the raw.json file doesn't already exist
[ ! -f $reportDir/${account}.raw.json ] &&
  prowler $prowlerArgs \
    -M json -b \
    > $reportDir/${account}.raw.json \
    || true   # so a failed test doesn't quit the script

jq -rs . $reportDir/${account}.raw.json \
  > $reportDir/${account}.json

#jsoncsv < $reportDir/${account}.raw.json \
 # | mkexcel > $reportDir/${account}.csv
#jsoncsv $reportDir/${account}.json > $reportDir/${account}.csv

exit 0

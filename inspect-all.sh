#!/bin/bash

set -eu

find ~/nbs-cloudmapper-results/ -name '*.tgz' \
  | awk -F / '{ print $5" "$10 }' \
  | sed -e 's/\.tgz$//' \
  | while read -r account scanId; do \
    echo ./inspect-wrapper.sh -a $account -s $scanId
  done

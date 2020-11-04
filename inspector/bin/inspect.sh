#!/bin/bash
set -eu

chosenAccount="${ACCOUNT_ID}"

echo "configuring cloudmapper for account $chosenAccount"
python3 cloudmapper.py configure add-account --id $chosenAccount --name $chosenAccount

python3 cloudmapper.py prepare --account $chosenAccount
python3 cloudmapper.py weboftrust --accounts $chosenAccount

python3 cloudmapper.py webserver --public >/dev/null &

echo "dropping into shell"
bash -il

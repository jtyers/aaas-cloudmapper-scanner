#!/bin/sh

set -eu

resources=$(cd $(dirname $0)/terraform \
  && terraform show -json \
  | jq '.values.root_module.resources')

docker run --rm -it \
  -e QUEUE_URL=$(jq -r 'map(select(.address=="aws_sqs_queue.queue")) | .[0].values.id' <<<"$resources") \
  -e BUCKET_NAME=$(jq -r 'map(select(.address=="aws_s3_bucket.result")) | .[0].values.bucket' <<<"$resources") \
  -e RANDOM_WAIT="" \
  -e AWS_DEFAULT_REGION=$(jq -r 'map(select(.address=="data.aws_region.current")) | .[0].values.name' <<<"$resources") \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN \
  scanner

# cloudmapper-scanner

Similar to `prowler-scanner`, this is a wrap-around for running Cloudmapper scans of a given environment.

It consists of a lambda 'invoker' and an EC2 Spot fleet that does the work:

* `cloudmapper-scanner-invoker` is called to start the scan. It validates inputs and pushes jobs to SQS.
* the SQS queue has a lambda trigger that scales up an ASG, which are our workers
* workers in the ASG (probably max 1 worker to start with) run the scan

The scan itself is a simple wrapper script around cloudmapper which:

* pulls any existing `account-data` from the S3 results bucket for the account/region
* runs `cloudmapper.py collect` to pull in new account data
* uploads the result back to S3 via `aws s3 sync`

When we come to analyse/present the results of cloudmapper, the Lambda responsible can then do similar, pulling
the data from S3, extracting it to a temporary location, and running `cloudmapper.py` using that same data.

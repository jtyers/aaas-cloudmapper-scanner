#!/bin/sh
set -eu

# these vars are templated in by Terraform
export QUEUE_URL="${queue_url}"
export REGION="${region}"
export BUCKET_NAME="${bucket_name}"
export RANDOM_WAIT="${random_wait}"

apt-get update

  # the ubuntu AMI comes with build-essential and git installed, but a host of other tools
  # are required by pip to build the pip deps
apt-get install -y python3-pip autoconf libtool jq awscli
  # FIXME: do we need awscli/boto3 too?

git clone --depth=1 https://github.com/duo-labs/cloudmapper.git /opt/cloudmapper
pip3 install -r /opt/cloudmapper/requirements.txt

echo "${cloudmapper_scanner_code}" \
  | base64 -d \
  | tar zxf - -C /opt/

# FIXME setup a dedicated user that doesn't have sudo access for this
# unfortunately cloudmapper is tightly coupled to running inside its repo,
# so it's easier to grant ourselves access to the entire tree there; specifically
# we need access to data/ account-data/ web/ and config.json (at least, so far...)
chown -R ubuntu /opt/cloudmapper

invoke=/opt/handler-invoke
cat <<EOF > $invoke
#!/bin/sh
export QUEUE_URL="${queue_url}"
export AWS_DEFAULT_REGION="${region}"
export BUCKET_NAME="${bucket_name}"
export RANDOM_WAIT="${random_wait}"

python3 /opt/handler.py
EOF

chmod +x $invoke
su -c $invoke - ubuntu

# after the wrapper completes, shut down
#poweroff

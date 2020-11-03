#!/bin/sh
apt-get update

  # the ubuntu AMI comes with build-essential and git installed, but a host of other tools
  # are required by pip to build the pip deps
apt-get install -y python3-pip autoconf libtool openssh-server
  # FIXME: do we need awscli/boto3 too?

git clone --depth=1 https://github.com/duo-labs/cloudmapper.git /opt/cloudmapper
pip3 install -r /opt/cloudmapper/requirements.txt

chown -R cloudmapper /opt/cloudmapper

cat <<EOF > /opt/cloudmapper-wrapper.py
#!/usr/bin/env python3

sqs = boto3.client("sqs")

queue_url = "${var_queue_url}"
max_messages = 3
max_wait_time = 120

def process_message(message_body):
    print(f"processing message: {}".format(message_body))
    
    # do what you want with the message here
    pass

if __name__ == "__main__":
    # receive a max of 3 messages, with a 5-minute timeout; and after that turn off
    # the instance (so the ASG scales down again)
    messages = sqs.receive_message(
      QueueUrl=queue_url,
      MaxNumberOfMessages=max_messages,
      WaitTimeSeconds=max_wait_time,
    )

    for message in messages:
        process_message(json.loads(message.body))
        message.delete()

EOF

chmod +x /opt/cloudmapper-wrapper.py

/opt/cloudmapper-wrapper.py

# after the wrapper completes, shut down
poweroff

FROM ubuntu
  RUN apt-get update \
    && DEBIAN_FRONTEND='noninteractive' \
       apt-get install -y python3-pip autoconf libtool jq awscli build-essential git awscli

  RUN git clone --depth=1 https://github.com/duo-labs/cloudmapper.git /opt/cloudmapper \
    && pip3 install -r /opt/cloudmapper/requirements.txt

  COPY function/* /opt/

  RUN useradd -m cloudmapper

  # unfortunately cloudmapper is tightly coupled to running inside its repo,
  # so it's easier to grant ourselves access to the entire tree there; specifically
  # we need access to data/ account-data/ web/ and config.json (at least, so far...)
  RUN chown -R cloudmapper /opt/cloudmapper

  ENTRYPOINT [ "python3", "/opt/handler.py" ]

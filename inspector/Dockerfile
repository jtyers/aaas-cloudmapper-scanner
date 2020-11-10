FROM python:3.7-slim

  ## Lifted from cloudmapper Dockerfile, as our container needs to be a git clone rather than copy of the code
  ENV AWS_DEFAULT_REGION=us-east-1 

  RUN apt-get update -y
  RUN apt-get install -y build-essential autoconf automake libtool \
    python3.7-dev python3-tk jq awscli bash git

  RUN git config --global user.email "foo@bar.com" \
    && git config --global user.name "foo"
  RUN git clone https://github.com/duo-labs/cloudmapper.git /opt/cloudmapper
  
  WORKDIR /opt/cloudmapper
  RUN pip install -r requirements.txt

  ## End of lift

  # for some reason args passed to the container to not seem
  # to get picked up by our entrypoint script, so we instead
  # use $ACCOUNT_ID to pass the account ID to inspect.sh

  RUN apt update
  RUN apt install -y fzy curl

  # add in any feature-fix branches we want
  RUN cd /opt/cloudmapper \
    && git remote add  jtyers https://github.com/jtyers/cloudmapper.git \
    && git pull --commit jtyers fix-unavailable-resources \
    && git pull --commit jtyers weboftrust-handle-unknown

# https://summitroute.com/blog/2018/06/12/cloudmapper_sg_ips/
#  #libgeos-3.7.1 libgeos-c1v5 libgeos-dev tk
#  RUN pip install --user https://github.com/matplotlib/basemap/archive/master.zip
#
#  RUN \
#    mkdir -p data; cd data \
#    && curl http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
#    && tar -zxvf GeoLite2-City.tar.gz \
#    && mv GeoLite2-City_*/GeoLite2-City.mmdb . \
#    && curl http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN.tar.gz \
#    && tar -zxvf GeoLite2-ASN.tar.gz \
#    && mv GeoLite2-ASN*/GeoLite2-ASN.mmdb . \
#    && rm -rf GeoLite2-City_* \
#    && rm -rf GeoLite2-ASN_* \
#    && rm -rf GeoLite2-*.tar.gz \
#    && cd ..
#
# # to run sg_ips, we need to install basemap, which has no pip package
# RUN cd /tmp \
#   && curl https://codeload.github.com/matplotlib/basemap/tar.gz/v1.1.0 --output basemap-1.1.0.tar.gz \
#   && tar -zxvf basemap-1.1.0.tar.gz \
#   && cd basemap-1.1.0/ \
#   && python setup.py install \
#   && cd /tmp \
#   && rm -rf basemap-1.1.0*

  COPY . /usr/local/

  ENTRYPOINT ["bash"]
  CMD [ "-c", "/usr/local/bin/inspect.sh" ]

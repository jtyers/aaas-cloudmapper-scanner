FROM cloudmapper
  # for some reason args passed to the container to not seem
  # to get picked up by our entrypoint script, so we instead
  # use $ACCOUNT_ID to pass the account ID to inspect.sh

  RUN apt update
  RUN apt install -y fzy curl 

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

  ENTRYPOINT '/usr/local/bin/inspect.sh'

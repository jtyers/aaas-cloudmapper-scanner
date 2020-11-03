FROM ubuntu AS function-builder
  ENV PROWLER_VERSION=2.2.0

  RUN apt update \
    && apt install -y zip curl

	# install prowler
  RUN mkdir /function \
    && curl -OfSL https://github.com/toniblyx/prowler/archive/$PROWLER_VERSION.tar.gz \
    && tar zxf $PROWLER_VERSION.tar.gz -C /function \
    && mv /function/prowler-$PROWLER_VERSION /function/prowler

  # add our scripts
  COPY ./function /function

  RUN cd /function \
    && zip -qr /function.zip .

FROM ubuntu AS layer-builder
  RUN apt update \
    && apt install -y python3-pip zip

  COPY requirements.txt .
  RUN mkdir -p /layer/python \
    && pip3 install -qq -r requirements.txt -t /layer/python

  RUN cd /layer \
    && zip -qr /layer.zip .

FROM ubuntu
  COPY --from=function-builder /function.zip .
  COPY --from=layer-builder /layer.zip .

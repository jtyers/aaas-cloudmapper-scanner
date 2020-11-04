FROM ubuntu AS function-builder
  ENV PROWLER_VERSION=2.2.0

  RUN apt update \
    && apt install -y git curl

  # add our scripts
  COPY ./function /function

  RUN tar czf /function.tgz -C /function .

FROM ubuntu AS layer-builder
  RUN apt update \
    && apt install -y python3-pip zip

  COPY requirements.txt .
  RUN mkdir -p /layer/python \
    && pip3 install -qq -r requirements.txt -t /layer/python

  RUN cd /layer \
    && zip -qr /layer.zip .

FROM ubuntu
  COPY --from=function-builder /function.tgz .
  COPY --from=layer-builder /layer.zip .

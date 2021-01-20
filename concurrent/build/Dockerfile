FROM alpine:latest

WORKDIR /root/

RUN apk update && apk add bash

RUN apk add --update -t deps curl && \
 curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && \
 chmod +x ./kubectl && \
 mv ./kubectl /usr/local/bin/kubectl && \
 apk del --purge deps && \
 rm /var/cache/apk/*

ADD ./kubeconfig.cfg ./.kube/config

ADD ./measurement.sh ./measurement.sh

RUN chmod +x ./measurement.sh

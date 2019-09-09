FROM crosscloudci/k8s-infra-deps:latest
MAINTAINER "W Watson <w.watson@vulk.coop>"

COPY . /k8s-infra

RUN cd /k8s-infra && \
      bundle install

      CMD [ "irb" ]

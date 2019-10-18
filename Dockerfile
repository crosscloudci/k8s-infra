FROM crosscloudci/k8s-infra-deps:latest
MAINTAINER "W Watson <w.watson@vulk.coop>"

COPY . /k8s-infra

WORKDIR /k8s-infra

RUN bundle install

RUN rake install

RUN python3 -m pip install pip -U && python3 -m pip install -r lib/provisioner/kubespray/kubespray/tests/requirements.txt && python3 -m pip install -r lib/provisioner/kubespray/kubespray/requirements.txt

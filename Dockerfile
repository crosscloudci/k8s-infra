FROM crosscloudci/k8s-infra-deps:latest
MAINTAINER "W Watson <w.watson@vulk.coop>"

COPY . /k8s-infra

RUN cd /k8s-infra && \
      bundle install

WORKDIR /k8s-infra

RUN rake install

RUN python3 -m pip install pip -U && python3 -m pip install -r lib/provisioner/kubespray/kubespray/tests/requirements.txt && python3 -m pip install -r lib/provisioner/kubespray/kubespray/requirements.txt
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.14.4/bin/linux/amd64/kubectl \
    && chmod a+x kubectl && cp kubectl /usr/local/bin/kubectl

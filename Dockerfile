FROM crosscloudci/k8s-infra-deps:latest
MAINTAINER "W Watson <w.watson@vulk.coop>"

COPY . /k8s-infra

WORKDIR /k8s-infra

RUN bundle install

RUN rake install

RUN python3 -m pip install pip -U && python3 -m pip install -r lib/provisioner/kubespray/kubespray/tests/requirements.txt && python3 -m pip install -r lib/provisioner/kubespray/kubespray/requirements.txt

RUN cd lib/provisioner/kubespray/kubespray/ \
    && /usr/bin/python3 -m pip install --no-cache-dir pip -U \
    && /usr/bin/python3 -m pip install --no-cache-dir -r tests/requirements.txt \
    && python3 -m pip install --no-cache-dir -r requirements.txt \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1

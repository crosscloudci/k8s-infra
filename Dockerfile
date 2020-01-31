FROM crosscloudci/k8s-infra-deps:latest
MAINTAINER "W Watson <w.watson@vulk.coop>"

COPY . /k8s-infra

WORKDIR /k8s-infra

RUN bundle install

RUN rake install

RUN python3 -m pip install pip -U && python3 -m pip install -r lib/provisioner/kubespray/kubespray/tests/requirements.txt && python3 -m pip install -r lib/provisioner/kubespray/kubespray/requirements.txt

# Apply Kubespray Patches
RUN patch lib/provisioner/kubespray/kubespray/roles/kubernetes-apps/network_plugin/meta/main.yml patches/kubernetes-apps/main.yml.patch
RUN patch lib/provisioner/kubespray/kubespray/roles/network_plugin/meta/main.yml patches/network_plugin/main.yml.patch
RUN patch lib/provisioner/kubespray/kubespray/roles/network_plugin/calico/templates/cni-calico.conflist.j2 patches/network_plugin/cni-calico.conflist.j2.patch
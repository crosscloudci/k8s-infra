# Kubespray
 `mkdir -p lib/provisioner/kubespray`
 `git clone https://github.com/kubernetes-sigs/kubespray.git lib/provisioner/kubespray/kubespray` unless Dir.exists?("lib/provisioner/kubespray/kubespray")
 `cd lib/provisioner/kubespray/kubespray && git checkout tags/v2.18.0` unless Dir.exists?("lib/provisioner/kubespray/kubespray")

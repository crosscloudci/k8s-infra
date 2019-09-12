class Kubespray
  @cluster_hash
  def initialize(cluster_hash)
    @cluster_hash = cluster_hash
  end
  def provision_template
    %{
all:
  vars: 
     kube_version: <%= @cluster_hash['k8s_infra']['k8s_release'] %>
     kubeconfig_localhost: true
     kubectl_localhost: true
  hosts:
    <% @cluster_hash['k8s_infra']['nodes'].each_with_index do |x, index|  -%>
node<%=index %>:
      ansible_host: <%= x['addr'] %>
      ip: <%= x['addr'] %>
      access_ip: <%= x['role'] %>
    <% end  -%>
  children:
    kube-master:
      hosts:
        node1:
        node2:
    kube-node:
      hosts:
        node1:
        node2:
        node3:
        node4:
    etcd:
      hosts:
        node1:
        node2:
        node3:
    k8s-cluster:
      children:
        kube-master:
  }
  end
end

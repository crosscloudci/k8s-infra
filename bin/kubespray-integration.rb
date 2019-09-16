require 'open3'
require 'fileutils'
require 'logger'

class Kubespray
  @cluster_hash
  attr_accessor :logger

  def initialize(cluster_hash)
    @cluster_hash = cluster_hash
    if ENV["RUBY_ENV"]=="test" then
      @logger = Logger.new('../../logs/kubespray-test.log', 'weekly')
    else
      @logger = Logger.new('logs/kubespray.log', 'weekly')
    end
  end
  def start_kubespray
    @logger.debug "pwd: #{FileUtils.pwd()}"
    if ENV["RUBY_ENV"]=="test" then
      sampledir='../../lib/provisioner/kubespray/kubespray/inventory/sample/'
      plugindir='../../lib/provisioner/kubespray/kubespray'
      datadir="../../data/mycluster"
    else
      sampledir='lib/provisioner/kubespray/kubespray/inventory/sample/'
      plugindir='lib/provisioner/kubespray/kubespray'
      datadir="data/mycluster"
    end
    FileUtils.cp_r(sampledir, datadir)
    # output = `ansible-playbook -i #{datadir}/hosts.yml --become --become-user=root #{plugindir}/cluster.yml`
    # puts output
    # stdin, stdout, stderr, wait_thr = Open3.popen3('ansible-playbook', '-i', "#{datadir}/hosts.yml", "--become", "--become-user=root", "#{plugindir}/cluster.yml")
    stdout, stderr, exitstatus = "passed", "passed", 0
    if ENV["RUBY_ENV"] !="test" then # to actually provision using rspec uncomment this
      stdout, stderr, status = Open3.capture3('ansible-playbook', '-i', "#{datadir}/hosts.yml", "--become", "--become-user=root", "#{plugindir}/cluster.yml")
      exitstatus = status.exitstatus
    end
    @logger.info "stderr #{stderr}"
    @logger.info "stdout #{stdout}"
    @logger.info "status #{exitstatus}"
    puts "stderr #{stderr}"
    puts "stdout #{stdout}"
    puts "status #{exitstatus}"
    {stdout: stdout, stderr: stderr, exit_code: exitstatus}
  end
  def provision_template
%{
all:
  vars: 
     kube_version: <%= @cluster_hash['k8s_infra']['k8s_release'] %>
     kubeconfig_localhost: true
     kubectl_localhost: true
  hosts:
    <%- @cluster_hash['k8s_infra']['nodes'].each_with_index do |x, index| -%>
    node<%=index %>:
      ansible_host: <%= x['addr']%>
      ip: <%=x['addr']%>
      access_ip: <%=x['addr']%>
      <%- @cluster_hash['k8s_infra']['nodes'][index]['index']=index -%>
    <%- end -%>
  children:
    kube-master:
      hosts:
      <%- @cluster_hash['k8s_infra']['nodes'].each_with_index do |x, index|-%>
        <%- if x['role']=='master' then -%>
        node<%=x['index'] %>:
        <%- end -%>
      <%- end -%>
    kube-node:
      hosts:
      <%- @cluster_hash['k8s_infra']['nodes'].each_with_index do |x, index|-%>
        <%- if x['role']=='worker' then -%>
        node<%=x['index'] %>:
        <%- end -%>
      <%- end -%>
    etcd:
      hosts:
      <%- @cluster_hash['k8s_infra']['nodes'].each_with_index do |x, index|-%>
        <%- if x['role']=='master' then -%>
        node<%=x['index'] %>:
        <%- end -%>
      <%- end -%>
    k8s-cluster:
      children:
        kube-master:
        kube-node:
    calico-rr:
      hosts: {}
}
  end
end

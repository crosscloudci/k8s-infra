require 'open3'
require 'fileutils'
require 'logger'
require_relative './k8sutils'

class Kubespray
  #TODO initialize
  @cluster_hash
  attr_accessor :logger
  DATA_DIR = "data/mycluster" 
  BLOCK_SIZE = 1024

  def initialize(cluster_hash)
    @cluster_hash = cluster_hash
    if ENV["RUBY_ENV"]=="test" then
      @logger = Logger.new('../../logs/kubespray-test.log', 'weekly')
    else
      @logger = Logger.new('logs/kubespray.log', 'weekly')
    end
  end

  # Returns true if all files are EOF
  def all_eof(files)
    files.find { |f| !f.eof }.nil?
  end

  def set_urls(cluster_hash)
    if cluster_hash['k8s_infra']["provision_type"]=="direct" then
      @logger.debug "provision_type = direct"

      #Check if binaries are available
      if cluster_hash['k8s_infra']['release_type'] == 'head'
        cluster_hash['k8s_infra']['hyperkube_download_url'] ="https://storage.googleapis.com/kubernetes-release-dev/ci-cross/#{cluster_hash['k8s_infra']['k8s_release']}/bin/linux/amd64/hyperkube" 
      else 
        cluster_hash['k8s_infra']['hyperkube_download_url'] ="https://storage.googleapis.com/kubernetes-release/release/#{cluster_hash['k8s_infra']['k8s_release']}/bin/linux/amd64/hyperkube" 
      end 
      cluster_hash['k8s_infra']['kubeadm_download_url'] ="https://storage.googleapis.com/kubernetes-release/release/#{cluster_hash['k8s_infra']['stable_k8s_release']}/bin/linux/#{cluster_hash['k8s_infra']['arch']}/kubeadm" 
      cluster_hash['k8s_infra']['hyperkube_binary_checksum']= K8sUtils.k8s_sha(cluster_hash['k8s_infra']['hyperkube_download_url'])
      if cluster_hash['k8s_infra']['hyperkube_binary_checksum'].nil? then
        puts "hyperkube_binary_checksum is invalid" 
        exit 1
      end
      cluster_hash['k8s_infra']['kubeadm_binary_checksum']= K8sUtils.k8s_sha( cluster_hash['k8s_infra']['kubeadm_download_url'])
      if cluster_hash['k8s_infra']['kubeadm_binary_checksum'].nil? then
        puts "kubeadm_binary_checksum is invalid" 
        exit 1
      end
    end

    cluster_hash
  end

  def start_kubespray
    @logger.debug "pwd: #{FileUtils.pwd()}"
    if ENV["RUBY_ENV"]=="test" then
      sampledir=File.expand_path '../../lib/provisioner/kubespray/kubespray/inventory/sample/'
      plugindir=File.expand_path '../../lib/provisioner/kubespray/kubespray'
      datadir=File.expand_path "../../#{DATA_DIR}"
    else
      sampledir=File.expand_path 'lib/provisioner/kubespray/kubespray/inventory/sample/'
      plugindir=File.expand_path 'lib/provisioner/kubespray/kubespray'
      datadir=File.expand_path DATA_DIR
    end
    FileUtils.cp_r(sampledir, datadir)
    # output = `ansible-playbook -i data/mycluster/hosts.yml --become --become-user=root lib/provisioner/kubespray/kubespray/cluster.yml`
    # output = `ansible-playbook -i #{datadir}/hosts.yml --become --become-user=root #{plugindir}/cluster.yml`
    complete_stdout, complete_stderr, exitstatus = "passed", "passed", 0
    if ENV["RUBY_ENV"] =="test" then 
      command = "ansible-playbook -i #{datadir}/hosts.yml --become --become-user=root #{plugindir}/cluster.yml --check"
    else
      command = "ansible-playbook -i #{datadir}/hosts.yml --become --become-user=root #{plugindir}/cluster.yml"
    end
    puts "Running command: #{command}"
    Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
      stdin.close_write

      begin
        files = [stdout, stderr]

        until all_eof(files) do
          ready = IO.select(files)

          if ready
            readable = ready[0]
            # writable = ready[1]
            # exceptions = ready[2]

            readable.each do |f|
              fileno = f.fileno

              begin
                data = f.read_nonblock(BLOCK_SIZE)

                # Do something with the data...
                # puts "fileno: #{fileno}, data: #{data}"
                puts "#{data}"
                @logger.info "#{data}"
              rescue EOFError => e
                puts "fileno: #{fileno} EOF"
              end
            end
          end
        end
      rescue IOError => e
        puts "IOError: #{e}"
      end
      complete_stdin, complete_stdout,
      complete_stderr, exitstatus = stdin, stdout, stderr, wait_thr.value.exitstatus
    end
    {stdout: complete_stdout, stderr: complete_stderr, exit_code: exitstatus}
  end

  def provision_template
%{
all:
  vars: 
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'
    kube_version: <%= @cluster_hash['k8s_infra']['k8s_release'] %>
    kubeconfig_localhost: true
    kubectl_localhost: false
    hyperkube_download_url: <%= @cluster_hash['k8s_infra']['hyperkube_download_url'] %> 
    hyperkube_binary_checksum: <%= @cluster_hash['k8s_infra']['hyperkube_binary_checksum'] %>
    kubeadm_download_url: <%= @cluster_hash['k8s_infra']['kubeadm_download_url'] %>
    kubeadm_binary_checksum: <%= @cluster_hash['k8s_infra']['kubeadm_binary_checksum'] %>
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

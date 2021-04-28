require 'open3'
require 'fileutils'
require 'logger'
require 'json'
require 'yaml'
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
      if cluster_hash['k8s_infra']['release_type'] == 'head' then
        cluster_hash['k8s_infra']['kubelet_download_url'] ="https://storage.googleapis.com/kubernetes-release-dev/ci/#{cluster_hash['k8s_infra']['k8s_release']}/bin/linux/#{cluster_hash['k8s_infra']['arch']}/kubelet"
        cluster_hash['k8s_infra']['kubectl_download_url'] ="https://storage.googleapis.com/kubernetes-release-dev/ci/#{cluster_hash['k8s_infra']['k8s_release']}/bin/linux/#{cluster_hash['k8s_infra']['arch']}/kubectl"
      else
        cluster_hash['k8s_infra']['kubelet_download_url'] ="https://storage.googleapis.com/kubernetes-release/release/#{cluster_hash['k8s_infra']['k8s_release']}/bin/linux/#{cluster_hash['k8s_infra']['arch']}/kubelet"
        cluster_hash['k8s_infra']['kubectl_download_url'] ="https://storage.googleapis.com/kubernetes-release/release/#{cluster_hash['k8s_infra']['k8s_release']}/bin/linux/#{cluster_hash['k8s_infra']['arch']}/kubectl"
      end
      cluster_hash['k8s_infra']['kubeadm_download_url'] ="https://storage.googleapis.com/kubernetes-release/release/#{cluster_hash['k8s_infra']['stable_k8s_release']}/bin/linux/#{cluster_hash['k8s_infra']['arch']}/kubeadm" 
      cluster_hash['k8s_infra']['kubelet_binary_checksum']= K8sUtils.k8s_sha(cluster_hash['k8s_infra']['kubelet_download_url'])
      if cluster_hash['k8s_infra']['kubelet_binary_checksum'].nil? then
        puts "kubelet_binary_checksum is invalid" 
        exit 1
      end
      cluster_hash['k8s_infra']['kubectl_binary_checksum']= K8sUtils.k8s_sha(cluster_hash['k8s_infra']['kubectl_download_url'])
      if cluster_hash['k8s_infra']['kubectl_binary_checksum'].nil? then
        puts "kubectl_binary_checksum is invalid" 
        exit 1
      end
      cluster_hash['k8s_infra']['kubeadm_binary_checksum']= K8sUtils.k8s_sha(cluster_hash['k8s_infra']['kubeadm_download_url'])
      if cluster_hash['k8s_infra']['kubeadm_binary_checksum'].nil? then
        puts "kubeadm_binary_checksum is invalid" 
        exit 1
      end
    end

    cluster_hash
  end

  def latest_kubespray_release
    release_url = "https://api.github.com/repos/kubernetes-sigs/kubespray/releases/latest"
    response = Faraday.get release_url
    if response.status != 200
      @logger.error "Failed to get Kubespray release info"
      exit 1
    end
    results = JSON.parse(response.body)
    latest = results['tag_name']
    return "#{latest}"
  end

  def latest_supported_kubernetes(tag)
    version_url = "https://raw.githubusercontent.com/kubernetes-sigs/kubespray/#{tag}/roles/kubespray-defaults/defaults/main.yaml"
    response = Faraday.get version_url
    if response.status != 200
      @logger.error "Failed to Kubespray raw file"
      exit 1
    end
    parsed = YAML.load(response.body)
    return parsed['kube_version']
  end

  def update_kubespray(tag)
    if ENV["RUBY_ENV"]=="test" then
      kubedir=File.expand_path '../../lib/provisioner/kubespray/kubespray'
    else
      kubedir=File.expand_path 'lib/provisioner/kubespray/kubespray'
    end

    commands = [ ]
    commands.push("git -C #{kubedir} checkout master -q")
    commands.push("git -C #{kubedir} pull --all -q")
    commands.push("git -C #{kubedir} checkout tags/#{tag} -q")

    commands.each do |command|
      Open3.popen3(command) do |stdin, stdout, stderr, wait_thr|
        unless stderr.read.to_s.strip.empty?
          @logger.error "#{stderr.read}"
          exit 1
        end
      end
    end
    puts "Kubespray updated to #{tag}"
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
    # if @cluster_hash['k8s_infra']['arch'] == 'arm64'
    #   FileUtils.cp_r(sampledir, datadir)
    #   FileUtils.cp_r("#{plugindir}/roles/container-engine/containerd/vars/ubuntu.yml", "#{plugindir}/roles/container-engine/containerd/vars/ubuntu.yml")
    # else
    FileUtils.cp_r(sampledir, datadir)
    # end
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
    <%- if @cluster_hash['k8s_infra']['release_type']=='head' -%>
    kube_image_repo: gcr.io/kubernetes-ci-images
    <%- else -%>
    kube_image_repo: k8s.gcr.io
    <%- end -%>
    nodelocaldns_image_repo: gcr.io/google-containers/k8s-dns-node-cache
    dnsautoscaler_image_repo: gcr.io/google-containers/cluster-proportional-autoscaler-<%= @cluster_hash['k8s_infra']['arch'] %>
    kube_version: <%= @cluster_hash['k8s_infra']['k8s_release'] %>
    kube_major_version: <%= @cluster_hash['k8s_infra']['stable_k8s_release'].split(".").take(2).join(".") %>
    etcd_deployment_type: host
    container_manager: containerd
    download_container: False
    kubeconfig_localhost: true
    <%- if @cluster_hash['k8s_infra']['release_type']=='kubespray' -%>
    kube_network_plugin: calico
    kube_network_plugin_multus: true
    <%- end -%>
    kubectl_localhost: false
    kubelet_download_url: <%= @cluster_hash['k8s_infra']['kubelet_download_url'] %> 
    kubelet_binary_checksum: <%= @cluster_hash['k8s_infra']['kubelet_binary_checksum'] %>
    kubectl_download_url: <%= @cluster_hash['k8s_infra']['kubectl_download_url'] %> 
    kubectl_binary_checksum: <%= @cluster_hash['k8s_infra']['kubectl_binary_checksum'] %>
    kubeadm_download_url: <%= @cluster_hash['k8s_infra']['kubeadm_download_url'] %>
    kubeadm_binary_checksum: <%= @cluster_hash['k8s_infra']['kubeadm_binary_checksum'] %>
    <%- if @cluster_hash['k8s_infra']['arch']=='amd64' -%>
    helm_enabled: true
    helm_deployment_type: host
    <%- end -%>
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

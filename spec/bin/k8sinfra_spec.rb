require 'spec_helper'
require 'faraday'
require 'yaml'
require './bin/kubespray-integration.rb' 

# TODO: Add tests for all arguments and options to build_pipeline

# Gitlab command to test:
describe "bin/k8sinfra", :type => :aruba, :exit_timeout => 180 do
  DATA_DIR = "data/mycluster" 
  let(:cmd) { 'bin/k8sinfra' }

  it "prints a help message and exits with a 0 status if no arguments are given" do
    run_command(cmd)
    # expect(last_command_started).to be_successfully_executed 
    expect(last_command_started).to have_output /generate_config/
    expect(last_command_started).to have_output /help/
  end

  it "generate_config prints a an error and help message then exits with a 0 status if invalid arguments are given" do
    cmd_with_args = "#{cmd} generate_config --invalid-option"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /ERROR: "k8sinfra generate_config" was called with arguments/
  end

  it "generate_config will exit with an error if the cluster file already exists" do
    cmd_with_args = "rm /tmp/test.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../spec/bin/example_hosts.yml -o /tmp/test.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../spec/bin/example_hosts.yml -o /tmp/test.yml"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /already exists/
  end

  it "generate_config will exit with an error if the hosts file has invalid syntax" do
    cmd_with_args = "rm /tmp/test.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../example_hosts-invalid_syntax.yml -o /tmp/test.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /has syntax errors/
  end

  it "generate_config will exit with an error if the hosts file has invalid structure" do
    cmd_with_args = "rm /tmp/test.yml"
    run_command(cmd_with_args)
    sleep(2)
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../example_hosts-invalid_structure.yml -o /tmp/test.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /Hosts file has structure errors/
  end

  it "generate_config will show valid output without -o" do
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../spec/bin/example_hosts.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /master/
    expect(last_command_started).to have_output /worker/
    expect(last_command_started).to have_output /amd64/
    expect(last_command_started).to have_output /v1.16.0/
  end

  it "generate_config --infra-job should pull down the nodes yml from the job" do
    cmd_with_args = "#{cmd} generate_config --infra-job=168517"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /139.178.68.121/
  end

  it "generate_config --master-hosts and --worker-hosts pull ips from the cli" do
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6'"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /6.6.6.6/
    expect(last_command_started).to have_output /1.1.1.1/
  end

  it "provision will exit with an error if the hosts file has invalid syntax" do
    cmd_with_args = "#{cmd} provision --config-file=../../example_hosts-invalid_syntax.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /has syntax errors/
  end

  it "provision will exit with an error if the hosts file has invalid structure" do
    cmd_with_args = "#{cmd} provision --config-file=../../example_hosts-invalid_structure.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /Cluster file has structure errors/
  end

  it "provision config-file is required" do
    cmd_with_args = "#{cmd} provision --dry-run --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /No config-file specified/
  end

  it "provision will show valid output with --dry-run --summary" do
    #create a cluster config file
    cmd_with_args = "rm /tmp/fulltest.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6' -o /tmp/fulltest.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(5)
    stop_all_commands
    cmd_with_args = "#{cmd} provision --config-file '/tmp/fulltest.yml' --dry-run --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /ip/
    expect(last_command_started).to have_output /1.1.1.1/
    expect(last_command_started).to have_output /role/
  end

  it "provision without --summary should only show success and minimal output" do
    #create a cluster config file
    cmd_with_args = "rm /tmp/fulltest.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6' -o /tmp/fulltest.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} provision --config-file '/tmp/fulltest.yml' --dry-run"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /\/tmp\/hosts.yml/
    expect(last_command_started).to have_output /succeeded/
    expect(last_command_started).to_not have_output /ip/
    expect(last_command_started).to_not have_output /1.1.1.1/
    expect(last_command_started).to_not have_output /role/
  end

  it "should validate that there is at least 1 worker node" do
    cmd_with_args = "#{cmd} provision --config-file '../../spec/missing_worker.yml' --dry-run --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /Cluster config should have a worker node :/
  end

  it "should validate that there is at least 1 master node" do
    cmd_with_args = "#{cmd} provision --config-file '../../spec/missing_master.yml' --dry-run --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /Cluster config should have a master node :/
  end

  it "provision invalid --provision-type should fail" do
    #create a cluster config file
    cmd_with_args = "rm /tmp/fulltest.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --provision-type=local --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6' -o /tmp/fulltest.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(5)
    stop_all_commands
    cmd_with_args = "#{cmd} provision --config-file '/tmp/fulltest.yml' --dry-run --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /Provision type "local" is not supported. :/
  end
  it "provision --kubespray will show valid output with --dry-run --summary" do
    #create a cluster config file
    cmd_with_args = "rm /tmp/fulltest.yml"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6' -o /tmp/fulltest.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(5)
    stop_all_commands
    cmd_with_args = "#{cmd} provision --config-file '/tmp/fulltest.yml' --dry-run --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /ip/
    expect(last_command_started).to have_output /1.1.1.1/
    
    kubespray_hash = YAML.load_file('/tmp/hosts.yml')
    expect(kubespray_hash["all"]["hosts"]["node0"]["ansible_host"]).to eq("1.1.1.1")
  end
  it "starts kubespray and verifies that the master and worker can be on the same node" do
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1' --worker-hosts='1.1.1.1' -o /tmp/fulltest.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(2)
    stop_all_commands
    cmd_with_args = "#{cmd} provision --config-file '/tmp/fulltest.yml'"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(120)
    puts last_command_started.output
    cluster_hash = YAML.load_file("#{DATA_DIR}/hosts.yml")
    # ks = Kubespray.new(cluster_hash)
    # cluster = ks.start_kubespray
    expect(cluster_hash["all"]["hosts"].nil?).to eq false 
    expect(cluster_hash["all"]["vars"]["kubeadm_download_url"]).to match(/https:\/\/storage.googleapis.com\/kubernetes-release\/release/)
    expect(cluster_hash["all"]["vars"]["hyperkube_download_url"]).to match(/https:\/\/storage.googleapis.com\/kubernetes-release\/release/)
    expect(cluster_hash["all"]["vars"]["kubeadm_download_url"]).to match(/amd64/)
    expect(cluster_hash["all"]["vars"]["hyperkube_download_url"]).to match(/amd64/)
    expect(cluster_hash["all"]["vars"]["kubeadm_binary_checksum"].nil?).to eq false
  end
end


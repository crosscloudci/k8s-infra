require 'spec_helper'
require 'faraday'

# TODO: Add tests for all arguments and options to build_pipeline

# Gitlab command to test:
describe "bin/k8sinfra", :type => :aruba, :exit_timeout => 180 do
  # generate_config --ips-from-cncfci --other options
  #
  let(:cmd) { 'bin/k8sinfra' }

  it "prints a help message and exits with a 0 status if no arguments are given" do
    # run("pwd")
    #run(cmd)
    run_command(cmd)
    # expect(last_command_started).to be_successfully_executed 
    expect(last_command_started).to have_output /generate_config/
    expect(last_command_started).to have_output /help/
  end

  it "generate_config prints a an error and help message then exits with a 0 status if invalid arguments are given" do
    # run("pwd")
    #run(cmd)
    cmd_with_args = "#{cmd} generate_config --invalid-option"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /ERROR: "k8sinfra generate_config" was called with arguments/
  end

  it "generate_config will exit with an error if the hosts file has invalid syntax" do
    # run("pwd")
    #run(cmd)
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../example_hosts-invalid_syntax.yml -o /tmp/test.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /has syntax errors/
  end

  it "generate_config will exit with an error if the hosts file has invalid structure" do
    # run("pwd")
    #run(cmd)
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../example_hosts-invalid_structure.yml -o /tmp/test.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /Hosts file has structure errors/
  end

  it "generate_config will show valid output without -o" do
    # run("pwd")
    #run(cmd)
    cmd_with_args = "#{cmd} generate_config --hosts-file=../../spec/bin/example_hosts.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /master/
    expect(last_command_started).to have_output /worker/
    expect(last_command_started).to have_output /amd64/
    expect(last_command_started).to have_output /amd64/
                                    expect(last_command_started).to have_output /v1.15.3/
  end

  it "generate_config --infra-job should pull down the nodes yml from the job" do
    # run("pwd")
    #run(cmd)
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

  it "provision_config config-file is required" do
    cmd_with_args = "#{cmd} provision_config --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /No config-file specified/
  end

  it "provision_config will show valid output with --summary" do
    #create a cluster config file
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6' -o /tmp/fulltest.yml"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    sleep(5)
    stop_all_commands
    cmd_with_args = "#{cmd} provision_config --config-file '/tmp/fulltest.yml' --summary"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /ip/
    expect(last_command_started).to have_output /1.1.1.1/
    expect(last_command_started).to have_output /role/
  end

  # it "provision_config --kubespray will show valid output with --summary" do
  #   #create a cluster config file
  #   cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6' -o /tmp/fulltest.yml"
  #   puts "Running command: #{cmd_with_args}"
  #   run_command(cmd_with_args)
  #   sleep(5)
  #   stop_all_commands
  #   cmd_with_args = "#{cmd} provision_config --config-file '/tmp/fulltest.yml' --kubespray --summary"
  #   puts "Running command: #{cmd_with_args}"
  #   run_command(cmd_with_args)
  #   expect(last_command_started).to have_output /ansible_host/
  #   expect(last_command_started).to have_output /ip/
  #   expect(last_command_started).to have_output /1.1.1.1/
  #   expect(last_command_started).to have_output /access_ip/
  #   expect(last_command_started).to have_output /children/
  #   expect(last_command_started).to have_output /k8s-cluster/
  # end
end


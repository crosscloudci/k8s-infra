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

  it "generate_config will valid output without -o" do
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
    # run("pwd")
    #run(cmd)
    cmd_with_args = "#{cmd} generate_config --master-hosts='1.1.1.1,2.2.2.2,3.3.3.3' --worker-hosts='4.4.4.4,5.5.5.5,6.6.6.6'"
    puts "Running command: #{cmd_with_args}"
    run_command(cmd_with_args)
    expect(last_command_started).to have_output /6.6.6.6/
    expect(last_command_started).to have_output /1.1.1.1/
  end

  # it "generate_config will test.yml with syntax" do
  #   # run("pwd")
  #   #run(cmd)
  #   cmd_with_args = "#{cmd} generate_config --hosts-file=example_hosts.yml"
  #   puts "Running command: #{cmd_with_args}"
  #   run_command(cmd_with_args)
  #   expect(last_command_started).to have_output /has syntax errors/
  # end


  # describe "download_container()" do
  #   let(:integration_arg) { "--integration=onap" }
  #   let(:project_name) { "so" }
  #   # let(:release_type) { "stable" }
  #   # let(:release_arg) { "--release-type=#{release_type}" }
  #   let(:spec_dir) { File.expand_path('../..', __FILE__) }
  #   #let(:config_location) { "https://raw.githubusercontent.com/crosscloudci/cncf-configuration/integration/cross-cloud.yml" }
  #   let(:config_location) { File.join(spec_dir, "test-cross-cloud.yml") }

  #   it "retrieves a stable release container configured for that project in config specified in CROSS_CLOUD_YML environment" do
  #     ClimateControl.modify CROSS_CLOUD_YML: config_location do
  #       release_type="stable"
  #       release_arg = "--release-type=#{release_type}"
  #       cmd_with_args = "#{cmd} download_container #{integration_arg} #{release_arg} #{project_name}"
  #       puts "Environment var CROSS_CLOUD_YML: #{ENV['CROSS_CLOUD_YML']}"
  #       puts "Running command: #{cmd_with_args}"

  #       run(cmd_with_args)
  #       #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #       expect(last_command_started).to be_successfully_executed
  #     end
  #   end

  #   it "retrieves a stable release container configured for that project in config specified as commandline argument" do
  #     release_type="stable"
  #     release_arg = "--release-type=#{release_type}"
  #     config_location_arg = "--cross-cloud-config=#{config_location}"
  #     cmd_with_args = "#{cmd} download_container #{integration_arg} #{release_arg} #{config_location_arg} #{project_name}"
  #     puts "Running command: #{cmd_with_args}"

  #     run(cmd_with_args)
  #     #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #     expect(last_command_started).to be_successfully_executed
  #   end

  #   # TODO: fix config not found test and command line client
  #   # ClimateControl.modify CROSS_CLOUD_YML: "" do
  #   #   ENV.delete("CROSS_CLOUD_YML")
  #   #   it "exits with an error if the project configuration is not found" do
  #   #     puts "this should fail"
  #   #     release_type="stable"
  #   #     release_arg = "--release-type=#{release_type}"
  #   #
  #   #     cmd_with_args = "#{cmd} download_container #{integration_arg} #{release_arg} -d #{project_name}"
  #   #     puts "Running command: #{cmd_with_args}"
  #   #
  #   #     run(cmd_with_args)
  #   #     expect(last_command_started).to have_output(/ERROR -- : Failed to find configuration for project/)
  #   #     #expect(last_command_started.exit_status).to eq(1)
  #   #   end
  #   # end
  # # end

  # # xdescribe "download_container() for head release" do
  # #   let(:integration_arg) { "--integration=onap" }
  # #   let(:project_name) { "so" }
  # #   # let(:release_type) { "head" }
  # #   # let(:release_arg) { "--release-type=#{release_type}" }
  # #   let(:spec_dir) { File.expand_path('../..', __FILE__) }
  # #   #let(:config_location) { "https://raw.githubusercontent.com/crosscloudci/cncf-configuration/integration/cross-cloud.yml" }
  # #   let(:config_location) { File.join(spec_dir, "test-cross-cloud.yml") }

  #   it "retrieves a head release container configured for that project in config specified in CROSS_CLOUD_YML environment" do

  #     release_type="head"
  #     release_arg = "--release-type=#{release_type}"
  #     ClimateControl.modify CROSS_CLOUD_YML: config_location do
  #       cmd_with_args = "#{cmd} download_container #{integration_arg} #{release_arg} #{project_name}"
  #       puts "Environment var CROSS_CLOUD_YML: #{ENV['CROSS_CLOUD_YML']}"
  #       puts "Running command: #{cmd_with_args}"

  #       run(cmd_with_args)
  #       #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #       expect(last_command_started).to be_successfully_executed
  #     end
  #   end

  #   it "retrieves a head release container configured for that project in config specified as commandline argument" do
  #     release_type="head"
  #     release_arg = "--release-type=#{release_type}"
  #     config_location_arg = "--cross-cloud-config=#{config_location}"
  #     cmd_with_args = "#{cmd} download_container #{integration_arg} #{release_arg} #{config_location_arg} #{project_name}"
  #     puts "Running command: #{cmd_with_args}"

  #     run(cmd_with_args)
  #     #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #     expect(last_command_started).to be_successfully_executed
  #   end
  # end

  # describe "create_pinning" do
  #   let(:integration_arg) { "--integration=onap" }
  #   let(:project_name) { "so" }
  #   # let(:release_type) { "stable" }
  #   # let(:release_arg) { "--release-type=#{release_type}" }
  #   let(:spec_dir) { File.expand_path('../..', __FILE__) }
  #   #let(:config_location) { "https://raw.githubusercontent.com/crosscloudci/cncf-configuration/integration/cross-cloud.yml" }
  #   let(:config_location) { File.join(spec_dir, "test-cross-cloud.yml") }
  #   let(:config_location_arg) { "--cross-cloud-config=#{config_location}" }

  #   it "creates a pinning configuration for stable releases of the project" do
  #     release_type="stable"
  #     release_arg = "--release-type=#{release_type}"
  #     cmd_with_args = "#{cmd} create_pinnings #{integration_arg} #{release_arg} #{config_location_arg} #{project_name}"
  #     puts "Running command: #{cmd_with_args}"

  #     run(cmd_with_args)
  #     #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #     expect(last_command_started).to be_successfully_executed
  #   end

  #   it "creates a pinning configuration for head releases of the project" do
  #     release_type="head"
  #     release_arg = "--release-type=#{release_type}"
  #     cmd_with_args = "#{cmd} create_pinnings #{integration_arg} #{release_arg} #{config_location_arg} #{project_name}"
  #     puts "Running command: #{cmd_with_args}"

  #     run(cmd_with_args)
  #     #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #     expect(last_command_started).to be_successfully_executed
  #   end

  # end


  # describe "build_status" do
  #   let(:integration_arg) { "--integration=onap" }
  #   let(:project_name) { "so" }
  #   #let(:release_type) { "head" }
  #   #let(:release_arg) { "--release-type=#{release_type}" }
  #   let(:spec_dir) { File.expand_path('../..', __FILE__) }
  #   #let(:config_location) { "https://raw.githubusercontent.com/crosscloudci/cncf-configuration/integration/cross-cloud.yml" }
  #   let(:config_location) { File.join(spec_dir, "test-cross-cloud.yml") }
  #   let(:config_location_arg) { "--cross-cloud-config=#{config_location}" }

  #   #it "returns friendly message that stable build status is not supported from onap jenkins and displays it" do
  #   it "ignores request/noop for stable build status which is not supported for onap stable releases" do
  #     release_type="stable"
  #     release_arg = "--release-type=#{release_type}"
  #     cmd_with_args = "#{cmd} build_status #{integration_arg} #{release_arg} #{config_location_arg} #{project_name}"
  #     puts "Running command: #{cmd_with_args}"

  #     run(cmd_with_args)
  #     expect(last_command_started).to have_output("Build status: n/a")
  #     expect(last_command_started).to be_successfully_executed
  #   end

  #   it "retrieves the head (nightly) build status from onap jenkins and displays it" do
  #     release_type="head"
  #     release_arg = "--release-type=#{release_type}"
  #     cmd_with_args = "#{cmd} build_status #{integration_arg} #{release_arg} #{config_location_arg} #{project_name}"
  #     puts "Running command: #{cmd_with_args}"

  #     run(cmd_with_args)
  #     #expect(last_command_started).to have_output(/DEBUG OUTPUT HERE/)
  #     expect(last_command_started).to be_successfully_executed
  #  end
  # end
end


 

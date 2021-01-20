#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'

require 'tty-color'
require 'tty-spinner'
require 'pastel'
require 'aws-sdk-core'
require 'aws-sdk-eks'
require 'kubeclient'
require 'aws-sdk-ec2'
require 'aws-sdk-cloudwatch'
require 'aws-sdk-iam'
require 'fileutils'
require 'optparse'
require 'concurrent-ruby'
require 'yaml'

require 'pp'

require_relative 'log'
require_relative 'lib/hash'
require_relative 'lib/string'
require_relative 'lib/ringbuffer'
require_relative 'lib/version_manager'
require_relative 'cfg/kubeconfig'

Dir[File.join(__dir__, 'ui', '**', '*.rb')].each(&method(:require))
Dir[File.join(__dir__, 'model', '**', '*.rb')].each(&method(:require))

VERSION = File.read(File.join(File.dirname(__FILE__), './.version')).strip

$settings = {}

EXIT_GENERAL=1
EXIT_RENDER_ERROR=2

# default to env, or dev profile if nothing is specified
$settings[:profile] = ENV['AWS_PROFILE'] if ENV['AWS_PROFILE']
$settings[:profile] ||= 'default'

path = "#{ENV['HOME']}/.kube/config"

raise "Error - could not find kubernetes config #{path}" unless File.exist?(path)
# always preset to the current kubectx cluster
$settings[:cluster] = `cat ${HOME}/.kube/config | grep current-context | cut -d ' ' -f2`.chomp
$settings[:resource] = :nodes
$settings[:cloudwatch] = false
$settings[:verbose] = false

OptionParser.new do |opts|
  opts.banner = "kute [#{VERSION}] \nusage: kute.rb [options]"

  opts.on('-v', '--[no-]verbose', 'Log debug information to stdout') do |_|
    $settings[:verbose] = true
  end

  opts.on('--profile PROFILE', 'Specify the profile to use for connection') do |v|
    $settings[:profile] = v
  end

  opts.on('-m', '--maps', 'Start with a list of cluster config maps') do |_|
    $settings[:selected] = :config_maps
  end

  opts.on('-p', '--pods', 'List all pods running in the cluster') do |_|
    $settings[:selected] = :pods
  end

  opts.on('-g', '--generators', 'Start with a list of cluster pod generators [deployments, stateful sets, daemonsets and replicasets]') do |_|
    $settings[:selected] = :generators
  end

  opts.on('-s', '--services', 'Start with a list of cluster services') do |_|
    $settings[:selected] = :services
  end

  opts.on('-i', '--ingresses', 'Start with a list of cluster ingresses') do |_|
    $settings[:selected] = :ingresses
  end
end.parse!

context = KubeConfig.current_context

unless context
  Log.error "Unable to determine context for cluster: #{settings[:cluster]}"
  exit 1
end

# pp context
endpoint = context['server']
cluster_name=context['context']['cluster'].split('/').last
credentials = Aws::SharedCredentials.new(profile_name: $settings[:profile]).credentials

auth_options = {
  bearer_token: Kubeclient::AmazonEksCredentials.token(credentials, cluster_name)
}

instances = InstanceMapper.new(credentials, cluster_name, $settings)

begin
  version = Aws::EKS::Client.new(credentials: credentials, region: context['region']).describe_cluster(name: cluster_name)

  console = Ui::Console.new(
    VersionManager.new(version, endpoint, auth_options),
    context,
    instances)

  console.select($settings[:selected] || :nodes)
rescue Aws::EKS::Errors::ResourceNotFoundException => e
  puts "AWS_PROFILE: #{ENV["AWS_PROFILE"] || "not configured"}"
  puts "Role: #{Aws::STS::Client.new(credentials: credentials).get_caller_identity["arn"]}"
  puts "EKS cluster #{cluster_name} not found in region #{context['region']}."
  puts "Context used:"
  Logger.dump(context)
end


#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'

require 'tty-color'
require 'pastel'
require 'aws-sdk-core'
require 'aws-sdk-eks'
require 'kubeclient'
require 'aws-sdk-ec2'
require 'aws-sdk-cloudwatch'
require 'fileutils'
# require 'colorize' # TODO remove
require 'optparse'
require 'pp'

# rudimentary logger
$settings = {}

# default to env, or dev profile if nothing is specified
$settings[:profile] = ENV['AWS_PROFILE'] if ENV['AWS_PROFILE']
$settings[:profile] ||= 'default'

# always preset to the current kubectx cluster
$settings[:cluster] = `cat ${HOME}/.kube/config | grep current-context | cut -d ' ' -f2`.chomp
$settings[:resource] = :nodes

$pastel = Pastel.new

OptionParser.new do |opts|
  opts.banner = 'Usage: kute.rb [options]'

  opts.on('-v', '--[no-]verbose', 'Log debug information to stdout') do |_|
    $settings[:verbose] = true
  end

  opts.on('-p', '--profile', 'Specify the profile to use for connection') do |v|
    $settings[:profile] = v
  end

  opts.on('-n', '--cluster-name', 'Specify the cluster name for the bearer auth token') do |v|
    $settings[:cluster_name] = v
  end

  opts.on('-c', '--cluster', 'Specify the cluster you wish to connect to') do |v|
    $settings[:cluster] = v
  end
end.parse!

require_relative 'log'
require_relative 'cfg/kubeconfig'
require_relative 'view/node_report'
require_relative 'model/nodes'
require_relative 'model/instance_mapper'

# extract servers and endpoints
context = KubeConfig.extract.values.select{|v| v['name'] == $settings[:cluster]}.first

unless context
  Log.error "Unable to determine context for #{settings[:cluster]}"
  exit 1
end

endpoint = context['server']

credentials = Aws::SharedCredentials.new(profile_name: $settings[:profile]).credentials

# pp context

auth_options = {
  bearer_token: Kubeclient::AmazonEksCredentials.token(credentials, $settings[:cluster_name] || context['cluster_name'])
}

ssl_options = { verify_ssl: OpenSSL::SSL::VERIFY_NONE }

Log.dump " profile:", $pastel.cyan($settings[:profile])
Log.dump " context:", $pastel.cyan(context['name'])
Log.dump " cluster:", $pastel.cyan(context['cluster'])
Log.dump "endpoint:", $pastel.green(context['server'])
print "\n"

cluster_name=context['name'].split('/')[1]

instances = InstanceMapper.new(credentials, cluster_name)

client = Kubeclient::Client.new(
  endpoint,
  'v1',
  auth_options: auth_options,
  ssl_options: ssl_options
)

case $settings[:resource]
when :nodes
  nodes = Nodes.new(client).nodes
  puts NodeReport.new(nodes, instances.instances).render
end
# pp client.get_nodes

puts "\n"
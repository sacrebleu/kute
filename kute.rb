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
require 'fileutils'
# require 'colorize' # TODO remove
require 'optparse'
require 'concurrent-ruby'
# require 'concurrent-edge'

require 'pp'

require_relative 'ui/cards/nodes'
require_relative 'ui/controller/nodes'
require_relative 'ui/controller/pods'
require_relative 'ui/layout/layout'

# rudimentary logger
$settings = {}

# default to env, or dev profile if nothing is specified
$settings[:profile] = ENV['AWS_PROFILE'] if ENV['AWS_PROFILE']
$settings[:profile] ||= 'default'

# always preset to the current kubectx cluster
$settings[:cluster] = `cat ${HOME}/.kube/config | grep current-context | cut -d ' ' -f2`.chomp
$settings[:resource] = :nodes
$settings[:cloudwatch] = false

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

  opts.on('-w', '--cloudwatch', 'Add additional cloudwatch derived metrics at the expense of speed') do |v|
    $settings[:cloudwatch] = :enabled
  end
end.parse!

require_relative 'log'
require_relative 'cfg/kubeconfig'
require_relative 'ui/cards/nodes'
require_relative 'ui/cards/pods'
require_relative 'ui/console'
require_relative 'model/nodes'
require_relative 'model/pods'
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

cluster_name=context['name'].split('/')[1]


instances = InstanceMapper.new(credentials, cluster_name, $settings)

client = Kubeclient::Client.new(
  endpoint,
  'v1',
  auth_options: auth_options,
  ssl_options: ssl_options
)

console = Ui::Console.new(context)
console.nodes = Ui::Cards::Nodes.new(client, instances, context)
console.pods  = Ui::Cards::Pods.new(client,  context)
console.select(:nodes)


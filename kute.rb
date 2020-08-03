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
require 'optparse'
require 'concurrent-ruby'
# require 'wisper'

require 'pp'

require_relative 'log'
require_relative 'lib/hash'
require_relative 'lib/ringbuffer'
require_relative 'cfg/kubeconfig'

Dir[File.join(__dir__, 'ui', '**', '*.rb')].each(&method(:require))
Dir[File.join(__dir__, 'model', '**', '*.rb')].each(&method(:require))

VERSION = '0.0.11'

$settings = {}

EXIT_GENERAL=1
EXIT_RENDER_ERROR=2

# default to env, or dev profile if nothing is specified
$settings[:profile] = ENV['AWS_PROFILE'] if ENV['AWS_PROFILE']
$settings[:profile] ||= 'default'

# always preset to the current kubectx cluster
$settings[:cluster] = `cat ${HOME}/.kube/config | grep current-context | cut -d ' ' -f2`.chomp
$settings[:resource] = :nodes
$settings[:cloudwatch] = false
$settings[:verbose] = false

# $pastel = Pastel.new

OptionParser.new do |opts|
  opts.banner = "kute [#{VERSION}] \nusage: kute.rb [options]"

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

  opts.on('-m', '--maps', 'Start with a list of cluster config maps') do |_|
    $settings[:selected] = :config_maps
  end

  opts.on('-s', '--services', 'Start with a list of cluster services') do |_|
    $settings[:selected] = :services
  end

  opts.on('-i', '--ingresses', 'Start with a list of cluster ingresses') do |_|
    $settings[:selected] = :ingresses
  end
end.parse!

# extract servers and endpoints
context = KubeConfig.extract.values.select{|v| v['name'] == $settings[:cluster]}.first

unless context
  Log.error "Unable to determine context for #{settings[:cluster]}"
  exit 1
end

endpoint = context['server']

credentials = Aws::SharedCredentials.new(profile_name: $settings[:profile]).credentials

auth_options = {
  bearer_token: Kubeclient::AmazonEksCredentials.token(credentials, $settings[:cluster_name] || context['cluster_name'])
}

cluster_name=context['name'].split('/')[1]

instances = InstanceMapper.new(credentials, cluster_name, $settings)

client = Kubeclient::Client.new(
  endpoint,
  'v1',
  auth_options: auth_options,
  ssl_options: { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
)

clientv1beta = Kubeclient::Client.new(
  "#{endpoint}/apis/extensions",
  'v1beta1',
  auth_options: auth_options,
  ssl_options: { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
)

console = Ui::Console.new([client, clientv1beta], context, instances)
console.select($settings[:selected] || :nodes)


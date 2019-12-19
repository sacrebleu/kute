#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'

require 'aws-sdk-core'
require 'aws-sdk-eks'
require 'kubeclient'
require 'colorize'
require 'fileutils'
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
require_relative 'kubeconfig'
require_relative 'nodes'
require_relative 'node_report'

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

Log.dump " profile:", $settings[:profile].cyan
Log.dump " context:", context['name'].cyan
Log.dump " cluster:", context['cluster'].cyan
Log.dump "endpoint:", context['server'].green
print "\n"

client = Kubeclient::Client.new(
  endpoint,
  'v1',
  auth_options: auth_options,
  ssl_options: ssl_options
)

case $settings[:resource]
  when :nodes
    Nodes.new(client).render
end
# pp client.get_nodes

puts "\n"
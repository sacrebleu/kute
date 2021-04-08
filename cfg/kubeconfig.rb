# This utility class parses $HOME/.kube/config for necessary information and presents it in a format that kute
# can use
#
require 'yaml'

class KubeConfig
  # search path
  def self.path
    "#{ENV['HOME']}/.kube/config"
  end

  def self.current_context
    s = YAML.load_file path

    current_context = s['current-context']
    context = context(current_context, s['contexts'])
    # s['contexts'].select {|ctx| ctx['name'] == current_context }.first

    cl = s['clusters'].map do |s|
      {
        'cluster_name' => s['name'],
        'server' => s['cluster']['server'],
        'region' => eks_region(s['cluster']['server'])
      }
    end.select { |s| s['cluster_name'] == context['context']['cluster'] }.first

    cl.merge(context)
  end

  # use regex to extract the region from the server url
  def self.eks_region(s)
    s.match(/\w+-\w+-\d/).to_s if s.end_with?('.eks.amazonaws.com')
  end

  def self.context(desired_context, contexts)
    # if name looks like an arn, check for a context with the same ARN, othewise try the context name
    contexts.select { |c| c['name'].split('/').last == desired_context.split('/').last }.first
  end
end

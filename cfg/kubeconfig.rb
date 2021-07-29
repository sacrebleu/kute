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
    # determine the current context and region
    context = YAML.load_file(path)
    current = context['current-context']
    current_context = context['contexts'].select {|c| c['name'] == current }
    cluster_arn = current_context.first['context']['cluster']
    server = context['clusters'].select {|c| c['name'] == cluster_arn }.first['cluster']['server']
    region = cluster_arn.split(':')[3]

    puts 'Context:  %s' % context['current-context']
    puts 'EKS ARN:  %s' % cluster_arn
    puts 'Endpoint: %s' % server
    puts 'Region:   %s' % region

    current_context = s['current-context']
    raise 'No Current context set' unless current_context

    {
      region: region,
      name: current,
      server: server,
      cluster_arn: cluster_arn,
      cluster_name: cluster_arn.split('/').last
    }
  end
end

# This utility class parses $HOME/.kube/config for necessary information and presents it in a format that kute
# can use
#
require 'yaml'

class KubeConfig

  # search path
  def self.path
    "#{ENV["HOME"]}/.kube/config"
  end

  def self.current_context
    s = YAML.load_file path

    current_context = s['current-context']
    context = s['contexts'].select {|ctx| ctx['name'] == current_context }.first

    cl = s['clusters'].map do |s|
      {
        'cluster_name' => s['name'],
        'server' => s['cluster']['server'],
        'region' => eks_region(s['cluster']['server'])
      }
    end.select{ |s| s['cluster_name'] == context['context']['cluster'] }.first

    cl.merge(context)
  end

  # use regex to extract the region from the server url
  def self.eks_region(s)
    if s.end_with?('.eks.amazonaws.com')
      s.match(/\w+\-\w+\-\d/).to_s
    else
      nil
    end
  end

end

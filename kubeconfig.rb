# This utility class parses $HOME/.kube/config for necessary information and presents it in a format that kute
# can use
class KubeConfig

  # search path
  def self.path
    "#{ENV["HOME"]}/.kube/config"
  end

  # load kubeconfig and extract key items
  #
  # generate a map of
  #
  # cluster: {
  #   name: <name>,
  #   endpoint: <endpoint>,
  #   region: <region>
  #
  # }
  #
  def self.extract
    s = YAML.load_file path

    # link contexts to clusters
    res = Hash[s['contexts'].map do |s|
      n = s['name']
      c = s['context']['cluster']

      [
        c,  {
          'cluster' => c,
          'name' => n
        }
      ]
    end
    ]

    s['clusters'].map do |s|
      k = s['name']

      if res[k]
        res[k]['cluster_name'] = k.split('/')[1]
        res[k]['server'] = s['cluster']['server']
        res[k]['region'] = eks_region(s['cluster']['server'])
      else
         Log.dump "Unknown context in", path.cyan, ":",  k.yellow
      end
    end

    res
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
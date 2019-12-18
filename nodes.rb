# model for querying and rendering a view of a kubernetes cluster's nodes
# TODO: region of node
#
class Nodes
  COL_NODES   = 45
  COL_PODS    = 10
  COL_VOLS    = 10
  COL_STATUS  = 10
  COL_TAINTS  = 20
  COL_VERSION = 22
  COL_AFFINITY = 20

  COLUMNS = [
    COL_NODES,
    COL_PODS,
    COL_VOLS,
    COL_STATUS,
    COL_TAINTS,
    COL_AFFINITY,
    COL_VERSION
  ]

  def initialize(client, opts = {})
    @client = client
  end

  # expects structure of type
  # [{:type=>"MemoryPressure",
  #   :status=>"False",
  #   :lastHeartbeatTime=>"2019-12-18T17:25:40Z",
  #   :lastTransitionTime=>"2019-11-26T13:56:45Z",
  #   :reason=>"KubeletHasSufficientMemory",
  #   :message=>"kubelet has sufficient memory available"},
  #  {:type=>"DiskPressure",
  #   :status=>"False",
  #   :lastHeartbeatTime=>"2019-12-18T17:25:40Z",
  #   :lastTransitionTime=>"2019-11-26T13:56:45Z",
  #   :reason=>"KubeletHasNoDiskPressure",
  #   :message=>"kubelet has no disk pressure"},
  #  {:type=>"PIDPressure",
  #   :status=>"False",
  #   :lastHeartbeatTime=>"2019-12-18T17:25:40Z",
  #   :lastTransitionTime=>"2019-11-26T13:56:45Z",
  #   :reason=>"KubeletHasSufficientPID",
  #   :message=>"kubelet has sufficient PID available"},
  #  {:type=>"Ready",
  #   :status=>"True",
  #   :lastHeartbeatTime=>"2019-12-18T17:25:40Z",
  #   :lastTransitionTime=>"2019-11-26T13:56:45Z",
  #   :reason=>"KubeletReady",
  #   :message=>"kubelet is posting ready status"}]
  def node_conditions(conds)
    res = {}
    conds.map{ |k| res[k.type] = k.status  }
    res
  end

  # retrieve node list
  def nodes
    pods = {}

    @client.get_pods(field_selector: "status.phase=Running").map do |p|
      pods[p.spec.nodeName] ||= 0
      pods[p.spec.nodeName] += 1
    end

    @nodes ||= @client.get_nodes.map do |node|

      v_use = node.status[:volumesInUse]&.size || 0
      {
        name: node.metadata.name,
        kubeletVersion: node.status[:nodeInfo][:kubeletVersion],
        labels: node.metadata.labels.to_h,
        taints: node.spec.taints&.map {|e| "#{e.key}=#{e.value}:#{e.effect}"},
        capacity: {
          ebs_volumes: node.status[:capacity][:"attachable-volumes-aws-ebs"],
          cpus: node.status[:capacity][:cpu],
          ephemeral: node.status[:capacity][:"ephemeral-storage"],
          memory: node.status[:capacity][:memory],
          pods: node.status[:capacity][:pods]
        },
        available_capacity: {
          ephemeral: node.status[:allocatable][:"ephemeral-storage"],
          memory: node.status[:allocatable][:memory],
          ebs_volumes: node.status[:capacity][:"attachable-volumes-aws-ebs"].to_i - v_use,
          pods: node.status[:capacity][:pods].to_i - pods[node.metadata.name]
        },
        status: node_conditions(node.status.conditions),
        volumes: node.volumesInUse,
        volume_count: v_use,
        pods: pods[node.metadata.name]
      }
    end
  end

  # render to output
  def render
    output =  ""
    output << render_line('Node', 'Pods', 'Volumes', 'Status', 'Taints', 'Affinity', 'Version')

    nodes.each do |node| output << render_line(node[:name], pcap(node), vcap(node),
                                               status(node), taints(node),affinity(node),  ver(node))
    end

    puts output
  end

  def render_line(*args)
    s = ""
    args.each_with_index do |entry, idx|
      s << entry.rjust(COLUMNS[idx])
    end
    s << "\n"
    s
  end

  def pcap(node)
    res =  format("%d/%d", node[:pods], node[:capacity][:pods])
    res = "* #{res}" if node[:pods].to_f / node[:capacity][:pods].to_f > 0.8
    res
  end

  def vcap(node)
    res = format("%d/%d", node[:volume_count], node[:capacity][:ebs_volumes])
    res = "* #{res}" if node[:volume_count].to_f / node[:capacity][:ebs_volumes].to_f > 0.8
    res
  end

  def status(node)
    s = node[:status]
    res = if s['Ready'] != 'True'
      'X'
    elsif s['MemoryPressure'] != 'False'
      'Mem'
    elsif s['DiskPressure'] != 'False'
      'Dsk'
    elsif s['PIDPressure'] != 'False'
      'Pid'
    else
      'Ok'
    end
    res
  end

  def taints(node)
    # pp node[:taints]

    res = if node[:taints]&.any?{|s| s.start_with?('NodeWithImpaired') }
            'Impaired'
          elsif node[:taints]&.any?{|s| s.end_with?('PreferNoSchedule')}
            'PrefNoSchedule'
          elsif node[:taints]&.any?{|s| s.end_with?('NoSchedule')}
            "NoSchedule"
          else
            ""
          end
    res
  end

  def affinity(node)
    node[:labels][:'kubernetes.io/affinity'] || ''
  end

  def ver(node)
    node[:kubeletVersion]
  end

end
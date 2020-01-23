# model for querying and rendering a view of a kubernetes cluster's nodes
# TODO: region of node
#
class Nodes

  def initialize(client, opts = {})
    @client = client
  end

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
      labels = node.metadata.labels.to_h

      {
        name: node.metadata.name,
        age: node.metadata.creationTimestamp,
        region: labels[:"failure-domain.beta.kubernetes.io/zone"],
        kubeletVersion: node.status[:nodeInfo][:kubeletVersion],
        labels: labels,
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
end
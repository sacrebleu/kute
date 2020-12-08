# model for querying and rendering a cards of a kubernetes cluster's nodes
# TODO: region of node
#
module Model
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

      # for each pod, get its container statuses as well
      @client.get_pods(field_selector: "status.phase=Running").map do |p|
        s = (p.status.containerStatuses.select { |e| e.state.running || e.state.terminated&.exitCode == 0 }.length == p.spec.containers.length)

        # pp [p.status.containerStatuses.select { |e| e.state.running }.length, p.spec.containers.length, s]

        pods[p.spec.nodeName] ||=  {count: 0, status: true}
        pods[p.spec.nodeName][:pod_names] ||= []
        pods[p.spec.nodeName][:pod_names] << p.metadata.name
        pods[p.spec.nodeName][:count] += 1
        pods[p.spec.nodeName][:status] = pods[p.spec.nodeName][:status] && s
      end

      @client.get_nodes.map do |node|
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
            pods: node.status[:capacity][:pods].to_i - pods[node.metadata.name][:count]
          },
          status: node_conditions(node.status.conditions),
          volumes: node.volumesInUse,
          volume_count: v_use,
          pods: pods[node.metadata.name][:count],
          pod_names: pods[node.metadata.name][:pod_names],
          container_health: pods[node.metadata.name][:status]
        }
      end
    end

    def describe(name)
      node = @client.get_node(name)
      v_use = node.status[:volumesInUse]&.size || 0
      labels = node.metadata.labels.to_h

      pods = {}

      # for each pod, get its container statuses as well
      @client.get_pods(field_selector: "spec.nodeName=#{name}").map do |p|
        s = (p.status.containerStatuses.select { |e| e.state.running || e.state.terminated&.exitCode == 0 }.length == p.spec.containers.length)

        pods[p.spec.nodeName] ||=  {count: 0, status: true}
        pods[p.spec.nodeName][:pod_names] ||= []
        pods[p.spec.nodeName][:pod_names] << p.metadata.name
        pods[p.spec.nodeName][:count] += 1
        pods[p.spec.nodeName][:status] = pods[p.spec.nodeName][:status] && s
      end

      res = {
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
          pods: node.status[:capacity][:pods].to_i - pods[node.metadata.name][:count]
        },
        status: node_conditions(node.status.conditions),
        volumes: node.volumesInUse,
        volume_count: v_use,
        pods: pods[node.metadata.name][:count],
        pod_names: pods[node.metadata.name][:pod_names],
        container_health: pods[node.metadata.name][:status]
      }

      res
    end
  end
end

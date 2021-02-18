# model for querying and rendering deployments, daemonsets, replicasets and statefulsets
#
module Model
  class Generators
    def initialize(client)
      @client = client
    end

    # retrieve node list
    def generators
      res = @client.get_deployments.map do |p|
        {
          type: :deployment,
          name: p.metadata.name,
          labels: p.metadata.labels,
          namespace: p.metadata.namespace,
          creationTime: Time.parse(p.metadata.creationTimestamp)
        }
      end

      res << @client.get_daemon_sets.map do |p|
        {
          type: :daemon_set,
          name: p.metadata.name,
          labels: p.metadata.labels,
          namespace: p.metadata.namespace,
          creationTime: Time.parse(p.metadata.creationTimestamp)
        }
      end

      res << @client.get_replica_sets.map do |p|
        {
          type: :replica_set,
          name: p.metadata.name,
          labels: p.metadata.labels,
          namespace: p.metadata.namespace,
          creationTime: Time.parse(p.metadata.creationTimestamp)
        }
      end

      res << @client.get_stateful_sets.map do |p|
        {
          type: :stateful_set,
          name: p.metadata.name,
          labels: p.metadata.labels,
          namespace: p.metadata.namespace,
          creationTime: Time.parse(p.metadata.creationTimestamp)
        }
      end

      res.flatten.sort_by { |a| [a[:namespace], a[:name]] }
    end

    def describe(ingress, namespace, type)
      @client.send("get_#{type}", ingress, namespace)
    end
  end
end

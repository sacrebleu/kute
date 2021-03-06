# model for querying and rendering a cards of a kubernetes cluster's nodes
#
module Model
  class Pods
    def initialize(client)
      @client = client
    end

    # retrieve node list
    def pods(node = nil)
      res = if node
              @client.get_pods(field_selector: "spec.nodeName=#{node}")
            else
              @client.get_pods
            end

      pods = res.map do |p|
        {
          name: p.metadata.name,
          node: node,
          namespace: p.metadata.namespace,
          containers: p.spec.containers.length,
          volumes: p.spec.volumes.length,
          serviceAccount: p.spec.serviceAccount,
          status: p.status.phase,
          ip: p.status.podIP,
          running: p.status.containerStatuses&.select { |e| e.state.running }&.length,
          restarts: p.status.containerStatuses&.collect { |e| e[:restartCount] }&.reduce(:+),
          ports: (p.spec.containers || [])
            .map do |c|
                   "#{c.name} #{(c.ports || [])
                    .map { |p| "#{p[:protocol]}:#{p[:containerPort]}" }.join(',')}"
                 end
            .join(',')
        }
      end
      pods.sort_by { |a| [a[:namespace], a[:name]] }
    end

    def describe(pod, namespace)
      @client.get_pod pod, namespace
    end
  end
end

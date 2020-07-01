# model for querying and rendering a cards of a kubernetes cluster's nodes
# TODO: region of node
#
module Model
  class Pods
    def initialize(client)
      @client = client
    end

    # retrieve node list
    def pods(node)
      pods = @client.get_pods(field_selector: "spec.nodeName=#{node}").map do |p|
        {
          name: p.metadata.name,
          node: node,
          namespace: p.metadata.namespace,
          containers: p.spec.containers.length,
          volumes: p.spec.volumes.length,
          serviceAccount: p.spec.serviceAccount,
          status: p.status.phase,
          ip: p.status.podIP,
          running: p.status.containerStatuses.select { |e| e.state.running }.length,
          restarts: p.status.containerStatuses.collect { |e| e[:restartCount] }.reduce(:+),
          ports: (p.spec.containers || [])
                   .map{ |c| "#{c.name} #{(c.ports || [])
                                            .map{|p| "#{p[:protocol]}:#{p[:containerPort]}"}.join(",")}" }
                   .join(',')
        }
      end
      pods.sort!{|a,b| a[:name] <=> b[:name] }
      pods
    end

    def describe(pod, namespace)
      @client.get_pod $pastel.strip(pod), $pastel.strip(namespace)
    end
  end
end
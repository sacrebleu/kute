# model for querying and rendering a cards of a kubernetes cluster's nodes
#
module Model
  class Ingresses
    def initialize(client)
      @client = client
    end

    # retrieve node list
    def ingresses
      ingresses = @client.get_ingresses.map do |p|
        {
          name: p.metadata.name,
          namespace: p.metadata.namespace,
          creationTime: p.metadata.creationTimestamp,
          ingress:p.metadata.annotations.send("kubernetes.io/ingress.class"),
          status: p.status.loadBalancer.ingress ? :active : :inactive,
          loadbalancer: p.status.to_h&.dig(:loadBalancer, :ingress)&.first&.[](:hostname)
        }
      end
      ingresses.sort_by{ |a| [a[:namespace], a[:name]] }
    end

    def describe(ingress, namespace)
      @client.get_ingress ingress, namespace
    end
  end
end
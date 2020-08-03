# model for querying and rendering a card of a kubernetes cluster's services
#
module Model
  class Services
    def initialize(client)
      @client = client
    end

    # retrieve service list
    def services
      services = @client.get_services.map do |p|
        # pp p
        {
          age: p.metadata.creationTimestamp,
          name: p.metadata.name,
          namespace: p.metadata.namespace,
          app: p.metadata.labels&.app,
          ip: p.spec.clusterIP,
          ports: p.spec[:ports]&.map{|e| "#{e[:name]}:#{e[:port]}"}&.join(','),
          selector: p.spec[:selector]&.map{|k,v| "#{k}=#{v}"}&.join(','),
          type: p.spec[:type],
          load_balancer: p.status[:loadBalancer]&.ingress&.first&.hostname,
          external_name: p.spec.externalName
        }
      end
      services.sort_by{ |a| [a[:namespace], a[:name]] }
    end


    # describe a service in detail
    def describe(s, namespace)
      s = @client.get_service s, namespace
      s
    end
  end
end
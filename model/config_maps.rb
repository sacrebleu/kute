module Model
  # class to interrogate the kubernetes api for config maps
  class ConfigMaps
    attr_reader :client

    def initialize(client)
      @client = client
    end

    # retrieve node list
    def config_maps
      maps = @client.get_config_maps.map do |p|
        {
          name: p.metadata.name,
          namespace: p.metadata.namespace,
          labels: p.metadata.labels,
          creationTime: Time.parse(p.metadata.creationTimestamp),
          data: p.data
        }
      end
      maps.sort_by{ |a| [a[:namespace], a[:name]] }
    end

    def describe(name ,namespace)
      @client.get_config_map name, namespace
    end
  end
end
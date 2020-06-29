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
      @client.get_pods(field_selector: "spec.nodeName=#{node}").map do |p|
        pp p;
        {
          name: p.metadata.name,
          node: node
        }
      end
    end
  end
end
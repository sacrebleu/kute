# generates a cli output of a particular service belonging to an eks cluster
module Ui
  module Cards
    class Ingress

      attr_reader :ingress

      def initialize(client)
        @model = Model::Ingresses.new(client)
        @dt = Time.now
        @selected = -1
      end

      def color
        @color ||= Pastel.new
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(ingress)
        @source = ingress
        reload!
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        @ingress = @model.describe(@source.name, @source.namespace)
      end

      def _rj(s, w)
        Ui::Layout::Justifier.rjust(s, w)
      end

      def _lj(s, w)
        Ui::Layout::Justifier.ljust(s, w)
      end

      def loadbalancer(ingress)
        ingress.status.to_h&.dig(:loadBalancer, :ingress)&.first&.[](:hostname)
      end

      def render
        w = 11
        pp ingress

        out = <<~DONE
        
          #{ingress.metadata.namespace} / #{color.bold(ingress.metadata.name)}
        DONE

        out
      end
    end
  end
end
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

      def rules(w)
        out = ''
        ingress.spec.rules.map do |rule|
          entries = rule.to_h.except(:host)
          entries.map do |proto,route|
            route[:paths].map do |path|
              out << "#{proto}://#{rule[:host]}#{path[:path]} -> #{path[:backend][:serviceName]}:#{path[:backend][:servicePort]}"
            end.flatten.join(_lj("\n", w))
          end.flatten.join(_lj("\n", w))
        end.flatten.join(_lj("\n", w))
      end

      def render
        w = 16
        out = <<~DONE
          LoadBalancers: #{ingress.status.loadBalancer.ingress&.collect{|k| k[:hostname]}&.join(_lj("\n", w))} 
          Status:        #{ingress.status.loadBalancer.ingress ? 'Active' : color.yellow('Inactive')}

          annotations:   #{ingress.metadata.annotations&.to_h&.map {|k,v| "#{k}: #{color.cyan(v)}"}&.join(_lj("\n", w))}

          labels:        #{ingress.metadata.labels&.to_h&.map {|k,v| "#{k}: #{color.cyan(v)}"}&.join(_lj("\n", w))}

          rules:         #{rules(w)}
        DONE

        out
      end
    end
  end
end
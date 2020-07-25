# generates a cli output of a particular service belonging to an eks cluster
module Ui
  module Cards
    class Service

      attr_reader :service

      def initialize(client)
        @model = Model::Services.new(client)
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

      def for(service)
        @source = service
        reload!
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        @service = @model.describe(@source.name, @source.namespace)
      end

      def _rj(s, w)
        Ui::Layout::Justifier.rjust(s, w)
      end

      def _lj(s, w)
        Ui::Layout::Justifier.ljust(s, w)
      end

      def loadbalancer(service)
        s = service.status&.to_h || {}
        s[:loadBalancer] ? s[:loadBalancer][:ingress]&.map{|l| l[:hostname] }&.join(_lj('\n', 15)) : ''
      end

      def ports(w)
        service.spec.ports
          &.sort {|a,b| a[:name] <=> b[:name] }
          &.map do |p|
            "#{_lj(p[:name], 25)} [#{p[:protocol]}] #{p[:port]} -> #{p[:targetPort]}"
          end
          &.join(_lj("\n", w))
      end

      def render
        w = 11
        out = <<~DONE
        
          #{service.metadata.namespace} / #{color.bold(service.metadata.name)}
          [Type: #{color.cyan(service.spec.type)} - cluster IP: #{service.spec.clusterIP}]

          selector: #{service.spec.selector&.to_h&.map {|k,v| "#{k}: #{color.green(v)}"}&.join(_lj("\n", w))}

          labels:   #{service.metadata.labels&.to_h&.map {|k,v| "#{k}: #{color.cyan(v)}"}&.join(_lj("\n", w))}
          
          ports:    #{ports(w)}
          
        DONE

        if service.spec.type == 'LoadBalancer'
          out << <<~LB
            loadbalancers: #{loadbalancer(service)}
          LB
        end

        if service.spec.type == 'ExternalName'
          out << <<~EN
            External Name: #{color.yellow.bold(service.spec.externalName)}
          EN
        end

        out
      end
    end
  end
end
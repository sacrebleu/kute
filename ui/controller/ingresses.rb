require_relative 'base'

module Ui
  module Controller
    # ui to render ingress information
    class Ingresses < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the service report
      def render_model
        model.render
      end

      # when did we last refresh
      def render_refresh_time
        "#{@pattern ? "search: /#{@pattern}/" : ''} page: #{model.index} Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "[#{color.cyan.bold('n')}odes]",
          "[#{color.cyan.bold('s')}ervices]",
          "[config #{color.cyan.bold('m')}aps]",
        ].join(' ')
        "#{s}> "
      end

      def go_ingress_details(s)
        app.ingress_details.for_ingress(s)
        app.select(:ingress_details)
        done!
      end

      # service keypresses
      def handle(evt)
        super(evt)

        if evt.key.name == :left
          go_nodes
        end

        if evt.key.name == :right || evt.value == 'd' || evt.key.name == :enter || evt.key.name == :return
          go_ingress_details(model.selected)
        end

        if evt.value == '@'
          model.sort!(:service_name)
        end

        if evt.value == '/'
          begin
            deregister
            @pattern = (reader.read_line "search pattern:").strip
            model.filter!(@pattern)
            model.select_first!
            register
          rescue => e
            pp e.backtrace if $settings[:verbose]
            register
          end
        end

        taint!
      end
    end
  end
end
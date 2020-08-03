require_relative 'base'

module Ui
  module Controller
    # ui to render service information
    class Services < Base
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
          "[config #{color.cyan.bold('m')}aps]",
          "[#{color.green.bold('i')}ngresses]",
          "[#{color.cyan.bold('n')}odes]",

        ].join(' ')
        "#{s}> "
      end

      def go_service_details(s)
        app.service_details.for_service(s)
        app.select(:service_details)
        done!
      end

      # service keypresses
      def handle(evt)
        super(evt)

        if evt.key.name == :left || evt.value == 'n'
          go_nodes
        end

        if evt.key.name == :right || evt.value == 'd' || evt.key.name == :enter || evt.key.name == :return
          go_service_details(model.selected)
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
module Ui
  module Controller
    # ui to render node information
    class ServiceDetails < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      def for_service(service)
        model.for(service)
      end

      # when did we last refresh
      def render_refresh_time
        "Refresh: #{model.last_refresh.strftime('%Y-%m-%d %H:%M:%S')}"
      end

      # node commands
      def prompt
        s = [
          "#{color.cyan.bold('b')}ack"
        ].join(' ')

        "#{model.service.metadata.namespace}/#{model.service.metadata.name}: #{s}> "
      end

      def go_services(service)
        app.select(:services, false)
        app.services.scroll_to(service.metadata.name)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        go_services(model.service) if evt.key.name == :left || evt.value == 'b' || evt.value == 's'

        if evt.value == 'r' || evt.key.name == :enter
          model.reload!
          refresh(false)
        end

        taint!
      end
    end
  end
end

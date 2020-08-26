module Ui
  module Controller
    # ui to render node information
    class ConfigMapDetails < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      def for_map(map)
        model.for(map)
      end

      # when did we last refresh
      def render_refresh_time
        "Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "#{color.cyan.bold("b")}ack",
        ].join(' ')

        "#{model.map.namespace}/#{model.map.name}: #{s}> "
      end

      def go_config_maps(map)
        app.select(:config_maps, false)
        app.config_maps.scroll_to(map)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :left
          go_config_maps(model.map)
        end

        if evt.key.name == :up
          model.previous
          refresh(false)
        end

        if evt.key.name == :down
          model.next
          refresh(false)
        end

        taint!
      end
    end
  end
end
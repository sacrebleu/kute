module Ui
  module Controller
    # ui to render node information
    class ConfigMaps < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      # when did we last refresh
      def render_refresh_time
        "#{@pattern ? "search: /#{@pattern}/" : ''} page: #{model.index} Refresh: #{model.last_refresh.strftime('%Y-%m-%d %H:%M:%S')}"
      end

      # node commands
      def prompt
        s = [
          "[#{color.cyan.bold('n')}odes]",
          "[#{color.cyan.bold('i')}ngresses]",
          "[#{color.cyan.bold('s')}ervices]",
          "[#{color.cyan.bold('g')}enerators]"
        ].join(' ')
        "#{s}> "
      end

      def go_map_details(map)
        app.map_details.for_map(map)
        app.select(:map_details)
        done!
      end

      def scroll_to(map)
        model.scroll_to(map)
        refresh(false)
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        go_nodes if evt.key.name == :left

        go_map_details(model.selected) if evt.key.name == :right || evt.key.name == :enter || evt.key.name == :return

        model.sort!(:map_name) if evt.value == '@'

        if evt.value == '/'
          begin
            deregister
            @pattern = (reader.read_line 'search pattern:').strip
            model.filter!(@pattern)
            model.select_first!
            register
          rescue StandardError => e
            Log.error(e.backtrace)
            register
          end
        end

        taint!
      end
    end
  end
end

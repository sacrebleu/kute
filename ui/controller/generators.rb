module Ui
  module Controller
    # ui to render node information
    class Generators < Base
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
        "#{@pattern ? "search: /#{@pattern}/" : ''} page: #{model.index} Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "[#{color.green.bold('n')}odes]",
          "[#{color.green.bold('i')}ngresses]",
          "[#{color.green.bold('s')}ervices]",
          "[config #{color.green.bold('m')}aps]"
        ].join(' ')
        "#{s}> "
      end

      def go_generator_details(gen)
        app.generator_details.for_generator(gen)
        app.select(:generator_details)
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
        if evt.key.name == :left
          go_nodes
        end

        if evt.key.name == :right || evt.key.name == :enter || evt.key.name == :return
          go_generator_details(model.selected)
        end

        if evt.value == '@'
          model.sort!(:map_name)
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
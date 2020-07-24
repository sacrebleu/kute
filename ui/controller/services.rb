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
          "[#{color.cyan.bold("q")}uit]"
        ].join(' ')
        "#{s}> "
      end

      def go_nodes
        app.select(:nodes)
        done!
      end

      # service keypresses
      def handle(evt)
        super(evt)

        if evt.key.name == :left || evt.value == 'n'
          go_nodes
        end

        if evt.key.name == :up
          model.select_previous!
          refresh(false)
        end

        if evt.key.name == :down
          model.select_next!
          refresh(false)
        end

        if evt.key.name == :space
          model.next_page
        end

        if evt.value == 'b'
          model.previous_page
        end

        if evt.value == '^'
          model.first_page
        end

        if evt.value == '$'
          model.last_page
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

        if evt.value == '*'
          model.filter! nil
        end

        taint!
      end
    end
  end
end
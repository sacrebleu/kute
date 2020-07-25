require_relative 'base'

module Ui
  module Controller
    # ui to render node information
    class Nodes < Base
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
          "[#{color.green.bold('s')}ervices]",
          "[#{color.green.bold('i')}ngresses]",
          "[#{color.cyan('order')}: #pods (#{color.cyan.bold("a")}sc/#{color.magenta.bold("d")}esc), #{color.cyan('n')}ode name]",
        ].join(' ')
        "#{s}> "
      end

      def go_pods(node)
        app.pods.for_node(node)
        app.select(:pods)
        done!
      end

      def go_services
        app.select(:services)
        done
      end

      def go_ingresses
        app.select(:ingresses)
        done
      end

      # node keypresses
      def handle(evt)
        super(evt)

        if evt.key.name == :right || evt.value == 'p' || evt.key.name == :enter || evt.key.name == :return
          n = model.selected.to_s
          go_pods(n)
        end

        if evt.value == 's'
          go_services
        end

        if evt.value == 'i'
          go_ingresses
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

        if evt.value == 'a'
          model.sort!(:pods_ascending)
        end

        if evt.value == 'd'
          model.sort!(:pods_descending)
        end

        if evt.value == '@'
          model.sort!(:node_name)
        end

        if evt.value == '/'
          begin
            deregister
            @pattern = (reader.read_line "search pattern:").strip
            # @pattern = pattern.strip
            model.filter!(@pattern)
            model.select_first!
            register
          rescue => e
            pp e.backtrace
            register
          end
        end

        if evt.value == '*'
          model.filter! nil
        end

        if evt.key.name == :up
          model.select_previous!
        end

        if evt.key.name == :down
          model.select_next!
        end

        taint!
      end
    end
  end
end
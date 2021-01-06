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
          "[config #{color.green.bold('m')}aps]",
          "[#{color.green.bold('g')}enerators]",
          "[#{color.green.bold('i')}ngresses]",
          "[all #{color.green.bold('p')}ods]",
          "[#{color.green.bold('s')}ervices]",
          "[node de#{color.green.bold('t')}ails]",
          "[#{color.cyan('order')}: #pods (#{color.cyan.bold("a")}sc/#{color.magenta.bold("d")}esc), #{color.cyan('n')}ode name]",
        ].join(' ')
        "#{s}> "
      end

      def go_pods(node=nil)
        node ? app.pods.for_node(node) : app.pods.all
        app.select(:pods)
        done!
      end

      def go_node(node=nil)
        app.node_details.for_node(node)
        app.select(:node_details)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        if evt.key.name == :right || evt.key.name == :enter || evt.key.name == :return
          n = model.selected.to_s
          go_pods(n)
        end

        if evt.value == 't' || evt.value == '.'
          n = model.selected.to_s
          go_node(n)
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

        taint!
      end
    end
  end
end

module Ui
  module Controller
    # ui to render node information
    class NodeDetails < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      def for_node(pod)
        model.for(pod)
      end

      # render the node report
      def render_model
        model.render
      end

      # when did we last refresh
      def render_refresh_time
        "#{@pattern ? "search: /#{@pattern}/" : ''} Refresh: #{model.last_refresh.strftime('%Y-%m-%d %H:%M:%S')}"
      end

      # node commands
      def prompt
        s = [
          "[config #{color.green.bold('m')}aps]",
          "[#{color.green.bold('g')}enerators]",
          "[#{color.green.bold('i')}ngresses]",
          "[all #{color.green.bold('p')}ods]",
          "[#{color.green.bold('s')}ervices]",
          "[#{color.cyan('order')}: #pods (#{color.cyan.bold('a')}sc/#{color.magenta.bold('d')}esc), #{color.cyan('n')}ode name]"
        ].join(' ')
        "#{s}> "
      end

      def go_pods(node = nil)
        node ? app.pods.for_node(node) : app.pods.all
        app.select(:pods)
        done!
      end

      def go_nodes
        # app.nodes.refresh(true) unless node
        app.select(:nodes, false)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        go_nodes if evt.key.name == :left || evt.value == 'n'
      end
    end
  end
end

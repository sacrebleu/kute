require_relative 'base'

module Ui
  module Controller
    # ui to render node information
    class Pods < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      def for_node(node)
        model.for_node(node)
      end

      # when did we last refresh
      def render_refresh_time
        "Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "#{$pastel.cyan.bold("o")}rder",
          "#{$pastel.cyan.bold("q")}uit"
        ].join(' ')

        "#{model.node}: #{s}> "
      end

      def go_nodes
        app.select(:nodes)
        done!
      end

      def go_pod_details(pod)
        app.pod_details.for_pod(pod)
        app.select(:pod_details)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :left || evt.value == 'n'
          go_nodes
        end

        if evt.key.name == :right || evt.value == 'd' || evt.key.name == :enter || evt.key.name == :return
          go_pod_details(model.selected)
        end

        if evt.key.name == :up
          model.select_previous!
          refresh(false)
        end

        if evt.key.name == :down
          model.select_next!
          refresh(false)
        end

        taint!
      end
    end
  end
end
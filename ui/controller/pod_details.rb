require_relative 'base'

module Ui
  module Controller
    # ui to render node information
    class PodDetails < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      def for_pod(pod)
        model.for(pod)
      end

      # when did we last refresh
      def render_refresh_time
        "Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "#{$pastel.cyan.bold("b")}ack",
          "#{$pastel.cyan.bold("q")}uit"
        ].join(' ')

        "#{model.pod.metadata.namespace}/#{model.pod.metadata.name}: #{s}> "
      end

      def go_pods(pod)
        # puts "selecting node #{node}"
        app.select(:pods)
        app.pods.for_node(pod.metadata.node)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :left || evt.value == 'p'
          go_pods(model.pod.node)
        end

        if evt.value == 'r' || evt.key.name == :enter
          model.reload!
          refresh(false)
        end

        taint!
      end
    end
  end
end
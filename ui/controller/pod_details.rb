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
        "Refresh: #{model.last_refresh.strftime('%Y-%m-%d %H:%M:%S')}"
      end

      # node commands
      def prompt
        s = [
          "#{color.cyan.bold('b')}ack",
          "#{color.cyan.bold('l')}ogs",
          "#{color.cyan.bold('c')}ontainers"
        ].join(' ')

        "#{model.pod.metadata.namespace}/#{model.pod.metadata.name}: #{s}> "
      end

      def go_pods(pod)
        app.select(:pods, false)
        app.pods.for_node(pod.spec.nodeName)
        app.pods.scroll_to(pod.metadata.name)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :left || evt.value == 'p'
          model.unwatch_logs
          go_pods(model.pod)
        end

        if evt.value == 'r'
          model.reload!
          refresh(false)
        end

        if evt.value == 'l'
          model.watch_logs
          refresh(false)
        end

        if evt.value == 'c' || evt.key.name == :backspace
          model.unwatch_logs
          model.reload!
          refresh(false)
        end

        taint!
      end
    end
  end
end

require_relative 'base'

module Ui
  module Controller
    # ui to render node information
    class IngressDetails < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      def for_ingress(ingress)
        model.for(ingress)
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

        "#{model.ingress.metadata.namespace}/#{model.ingress.metadata.name}: #{s}> "
      end

      def go_ingresses(ingress)
        app.select(:ingresses, false)
        app.ingresses.scroll_to(ingress.metadata.name)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :left || evt.value == 'b' || evt.value == 'i'
          go_ingresses(model.ingress)
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
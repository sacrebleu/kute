require_relative 'base'

module Ui
  module Controller
    # ui to render node information
    class GeneratorDetails < Base
      attr_reader :model

      def initialize(console, model)
        super(console)
        @model = model
      end

      # render the node report
      def render_model
        model.render
      end

      def for_generator(generator)
        model.for(generator)
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

        "#{model.generator.metadata.namespace}/#{model.generator.metadata.name}: #{s}> "
      end

      def go_generators(generator)
        app.select(:generators, false)
        app.generators.scroll_to(generator.metadata.name)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :left || evt.value == 'p'
          go_generators(model.generator)
        end

        if evt.value == 'r'
          model.reload!
          refresh(false)
        end

        taint!
      end
    end
  end
end
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
        "Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "#{$pastel.cyan.bold("o")}rder",
          "#{$pastel.cyan.bold("p")}ods",
          "#{$pastel.cyan.bold("c")}loudwatch",
          "#{$pastel.cyan.bold("q")}uit"
        ].join(' ')
        "#{model.selected}: #{s}> "
      end

      def get_order
        [:order, reader.expand('Order by', auto_hint: false) do |q|
          q.choice key: 'a', name: 'Pods (ascending occupancy)', value: :pods_ascending
          q.choice key: 'd', name: 'Pods (descending occupancy)', value: :pods_descending
        end]
      end

      def go_pods(node)
        # puts "selecting node #{node}"
        app.pods.for_node(node)
        app.select(:pods)
        done!
      end

      # node keypresses
      def handle(evt)
        super(evt)

        # > and p both fetch pods from the selected node
        if evt.key.name == :right || evt.value == 'p'
          n = model.selected.to_s
          go_pods(n)
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
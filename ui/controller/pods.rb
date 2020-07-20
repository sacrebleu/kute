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
        "#{@pattern ? "search: /#{@pattern}/" : ''} page: #{model.index} Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
      end

      # node commands
      def prompt
        s = [
          "[order: #containers (#{color.cyan.bold("a")}sc/#{color.magenta.bold("d")}esc), pod #{color.cyan('n')}ame]",
          "[#{color.cyan.bold("q")}uit]"
        ].join(' ')
        "#{s}> "
      end

      def go_nodes
        app.select(:nodes)
        done!
      end

      def go_pod_details(pod)
        app.select(:pod_details)
        app.pod_details.for_pod(pod)
        done!
      end

      def scroll_to(pod)
        model.scroll_to(pod)
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
          model.sort!(:pod_name)
        end

        if evt.value == '#'
          model.sort!(:container_count)
        end

        if evt.value == '!'
          model.toggle!(:issues)
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
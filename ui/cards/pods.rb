# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Pods

      # models a row in the report
      class Row
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :region, :version, :age, :namespace, :serviceaccount,
                    :con, :vol, :ip, :rst, :ports

        def initialize(pod)
          @name = pod[:name]
          @namespace = pod[:namespace]
          @con = containers(pod)
          @con_status = pod[:running] == pod[:containers]
          @vol = pod[:volumes].to_s
          # @status = COLUMNS[4].trim pod[:status]
          @rst = pod[:restarts].to_s
          @ports = pod[:ports]
          @serviceaccount = pod[:serviceAccount]
          @ip = pod[:ip]
          @selected = false
        end

        def containers(pod)
          pod[:running] < pod[:containers] ?
            "#{$pastel.yellow(pod[:running])}/#{pod[:containers]}" : "#{pod[:running]}/#{pod[:containers]}"
        end

        def rejigger(columns)
          columns.each do |column|
            m = column.name
            column.rejigger($pastel.strip(send(m)).length + 1)
          end
        end

        def status
          @con_status ? "Ok" : $pastel.yellow("*")
        end

        def select!
          @selected = true
        end

        def selected?
          @selected
        end

        def deselect!
          @selected = false
        end

        def name
          if @selected
            $pastel.white.bold(@name)
          else
            @name
          end
        end

        # layout columns
        def render(columns)
          output = ''
          columns.each do |column|
            m = column.name
            output << column.render(send(m))
          end
          output
        end
      end

      attr_reader :node, :columns

      def initialize(client, context)
        @context = context
        @model = Model::Pods.new(client)
        @columns = [
          [:name,     45, :left],
          [:namespace, 20, :left],
          [:con, 7, :left],
          [:vol, 5, :left],
          [:status, 10, :left],
          [:rst, 5, :left],
          [:ports, 30, :left],
          [:serviceaccount, 20, :left],
          [:ip, 15, :left]
        ].map { |e| Ui::Layout::Column.new(*e) }.freeze
        @pods = []
        @dt = Time.now
        @selected = -1
      end

      # set the list of pods to render
      def for_node(node)
        @node = node
        refresh(true)
      end

      def refresh(fetch, order=:default)
        reload! if fetch

        select! if @selected > -1
        select_first! unless selected

        @dt = Time.now
      end

      # reload upstream data
      def reload!
        @pods = @model.pods(@node).map do |pod|
          r = Row.new(pod)
          r.rejigger(columns)
          r
        end
      end

      def render_header
        $pastel.bold.white(columns.collect(&:title).join('') << "\n")
      end

      def render_lines
        @pods.collect do |pod|
          pod.render(columns)
        end.join("\n") << "\n"
      end

      def render
        output = render_header
        output << render_lines
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      # get the currently selected row
      def selected
        @pods.any?(&:selected?) ? @pods.select(&:selected?).first : nil
      end

      def scroll_to(name)
        @selected = @pods.index {|p| $pastel.strip(p.name) == $pastel.strip(name) } || 0
        select!
      end

      def select!
        @pods[@selected].select!
      end

      # reset all node selection flags to false
      def clear_selection!
        @pods.each(&:deselect!)
      end

      # return true if the next node was selected, false otherwise
      def select_next!
        if selected && @selected < @pods.length - 1
          clear_selection!

          @selected = @selected + 1
          select!
        else
          false
        end
      end

      # return true if the previous node was selected, false otherwise
      def select_previous!
        if @selected > 0
          clear_selection!

          @selected = @selected - 1
          select!
        else
          false
        end
      end

      # select the first node in the current node ordering
      def select_first!
        @selected = 0
        clear_selection!
        @pods[@selected].select!
      end
    end
  end
end
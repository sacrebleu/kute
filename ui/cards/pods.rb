# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Pods

      # formatting utility class
      class Column
        attr_accessor :name, :width, :align

        def initialize(*ary)
          @name = ary[0]
          @width = ary[1]
          @align = ary.length > 2 ? ary[2] : :right
        end

        def align_right?
          @align == :right
        end

        # render this column's name according to the layout rules
        def title
          v = name.to_s.capitalize
          align_right? ? rjust(v) : ljust(v)
        end

        # render the target according to this column's layout rules
        def render(target)
          align_right? ? rjust(target) : ljust(target)
        end

        def rjust(source)
          empty = ' ' * (width - $pastel.strip(source).length)
          "#{empty}#{source}"
        end

        def ljust(source)
          empty = ' ' * (width - $pastel.strip(source).length)
          "#{source}#{empty}"
        end
      end

      # models a row in the report
      class Row
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :region, :version, :age

        def initialize(pod)
          @name = pod[:name]
          @selected = false
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

        # render an ansi status string for the pod
        def status
          'Ok'
        end

        # layout columns
        def render(columns)
          output = ''
          columns.each do |column|
            m = column.name
            # puts "#{m}=#{send(m)}"
            output << column.render(send(m))
          end
          output
        end
      end

      attr_reader :node

      def initialize(client, context)
        @context = context
        @model = Model::Pods.new(client)
        @columns = [
          [:name,     45, :left],
        ].map { |e| Column.new(*e) }.freeze
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
        select_first! unless selected?

        @dt = Time.now
      end

      # reload upstream data
      def reload!
        @pods = @model.pods(@node).map { |pod| Row.new(pod) }
        select_first!
      end

      # get the currently selected row
      def selected?
        @pods.any?(&:selected?) ? @pods.select(&:selected?).first : nil
      end

      def render_header
        @columns.collect(&:title).join('') << "\n"
      end

      def render_lines
        @pods.collect do |pod|
          pod.render(@columns)
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
        selected > -1 ? @pods[@selected] : nil
      end

      # reset all node selection flags to false
      def clear_selection!
        @pods.each(&:deselect!)
      end

      # return true if the next node was selected, false otherwise
      def select_next!
        if @selected < @pods.length - 1
          @pods[@selected].deselect!
          @selected = @selected + 1
          @pods[@selected].select!
          true
        else
          false
        end
      end

      # return true if the previous node was selected, false otherwise
      def select_previous!
        if @selected > 0
          @pods[@selected].deselect!
          @selected = @selected - 1
          @pods[@selected].select!
          true
        else
          false
        end
      end

      # select the first node in the current node ordering
      def select_first!
        if @selected > -1 && @selected < @pods.length
          @pods[@selected].deselect!
        end
        @selected = 0
        @pods[@selected]&.select!
      end
    end
  end
end
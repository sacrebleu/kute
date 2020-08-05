# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Generators < Base

      # models a row in the report
      class Row < Ui::Pane::SelectableRow
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :namespace, :name, :labels, :age, :color, :data, :type, :resource_type

        def initialize(map, color)
          @color = color
          @name = map[:name]
          @namespace = map[:namespace]
          @resource_type = map[:type]
          @type = display_type(map[:type])
          l = map[:labels]&.to_h&.collect{|k,v| "#{k}: #{v}"}&.join(',')
          @labels = (l && l.length > 60 ? l[0..57] + '...' : l)
          @age = Util::Duration.human(Time.now.to_i - map[:creationTime].to_i)
        end

        def display_type(type)
          # pp type
          if type == :replica_set
            color.yellow(type.to_s.split_case)
          elsif type == :daemon_set
            color.cyan(type.to_s.split_case)
          elsif type == :stateful_set
            color.green(type.to_s.split_case)
          else
            type.to_s.split_case
          end
        end

        def rejigger(columns)
          columns.each do |column|
            m = column.name
            v = send(m)
            column.rejigger(color.strip(v).length + 2) if v
          end
        end

        def render(columns)
          output = ''
          columns.each do |column|
            m = column.name
            if m == :name && @selected
              output << column.render(color.white.bold(@name) + color.bold.yellow(">"))
            else
              output << column.render(send(m))
            end
          end
          output
        end
      end

      attr_reader :node, :columns

      def initialize(client)
        # @context = context
        @model = Model::Generators.new(client)
        @columns = [
          [:name, 30, :left],
          [:namespace, 20, :left],
          [:type, 20, :left],
          [:age, 8, :left],
          [:labels, 60, :left]
        ].map { |e| Ui::Layout::Column.new(*e) }.freeze
        @generators = []
        @pane = Ui::Pane.new(@generators, pane_height)
        @dt = Time.now
        @pattern = ''
      end

      # set the list of pods to render

      def refresh(fetch, order=:default)
        reload! if fetch
        @pane.update!(@generators) if fetch
        @pane.first_row! if fetch

        @dt = Time.now
      end

      # reload upstream data
      def reload!
        @generators = @model.generators.map do |map|
          r = Row.new(map, @pane.color)
          r.rejigger(columns)
          r
        end
      end

      def render_header
        @pane.color.bold.white(columns.collect(&:title).join('') << "\n")
      end

      def render_lines
        @pane.view.collect do |row|
          row.render(@columns)
        end.join("\n") << "\n"
      end

      def render
        output = render_header
        output << render_lines
      end

      # scroll to the named pod
      def scroll_to(name)
        @pane.goto_row!(@pane.find(:name, name))
      end

      def pane_height
        TTY::Screen.height - 4 # leave space for columns + totals
      end

      # sort nodes by sort function - default is occupancy
      def sort!(method)
        if method == :name
          @pane.sort_by{|map| [map[:namespace], map[:name]]}
        end
      end

      def filter!(pattern)
        @pattern = pattern
        @pane.filter! { |map| /#{@pattern}/.match?(map.name) }
      end
    end

  end
end
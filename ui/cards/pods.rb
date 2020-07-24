# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Pods < Base

      # models a row in the report
      class Row < Ui::Pane::SelectableRow
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :region, :version, :age, :namespace, :serviceaccount,
                    :con, :vol, :ip, :rst, :color, :name

        def initialize(pod, color)
          @color = color
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
        end

        def containers(pod)
          pod[:running] < pod[:containers] ?
            "#{color.yellow(pod[:running])}/#{pod[:containers]}" : "#{pod[:running]}/#{pod[:containers]}"
        end

        def rejigger(columns)
          columns.each do |column|
            m = column.name
            v = send(m)
            column.rejigger(color.strip(v).length + 1) if v
          end
        end

        def ports
          @ports[0..30]
        end

        def status
          @con_status ? "Ok" : color.yellow("*")
        end

        # layout columns
        def render(columns)
          # pp columns
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

      def initialize(client, context)
        @context = context
        @model = Model::Pods.new(client)
        @columns = [
          [:name,     55, :left],
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
        @pane = Ui::Pane.new(@pods, pane_height)
        @dt = Time.now
        @pattern = ''
      end

      # set the list of pods to render
      def for_node(node)
        @node = node
        refresh(true)
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @pane.update!(@pods) if fetch
        @pane.first_row! if fetch

        @dt = Time.now
      end

      # reload upstream data
      def reload!
        @pods = @model.pods(@node).map do |pod|
          r = Row.new(pod, @pane.color)
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
        if method == :containers_descending
          @pane.sort! {|a, b| b.pod_occupancy_ratio <=> a.pod_occupancy_ratio }
        end

        if method == :containers_ascending
          @pane.sort!{|a, b| a.pod_occupancy_ratio <=> b.pod_occupancy_ratio }
        end

        if method == :node_name
          @pane.sort!{|a, b| a.name <=> b.name }
        end
      end

      def filter!(pattern)
        @pattern = pattern
        @pane.filter! { |pod| /#{@pattern}/.match?(pod.name) }
      end
    end
  end
end
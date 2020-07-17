# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Pods

      # models a row in the report
      class Row
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :region, :version, :age, :namespace, :serviceaccount,
                    :con, :vol, :ip, :rst

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

        def ports
          @ports[0..30]
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

        def plainname
          $pastel.strip(@name)
        end

        def name
          if @selected
            $pastel.white.bold(@name) + $pastel.bold.yellow(">")
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
        @dt = Time.now
        @selected = -1
        @page = 0
        @pattern = ''
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
        window.collect do |pod|
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
        @selected = @pods.index {|p| p.plainname == $pastel.strip(name) } || 0
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

          if @selected > window_idx_last
            next_page
          end

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

          if @selected < window_idx_first
            previous_page
          end

          select!
        else
          false
        end
      end

      # select the first node in the current node ordering
      def select_first!
        @selected = window_idx_first
        clear_selection!
        @pods[@selected].select!
      end

      def pane_height
        TTY::Screen.height - 4 # leave space for columns + totals
      end

      # next page
      def next_page
        @page += 1 if @pods && (@page + 1) * pane_height < @pods.length
        select_first!
      end

      # previous page
      def previous_page
        @page -= 1 if @page.positive?
        select_first! if @selected > window_idx_last
      end

      # first page
      def first_page
        @page = 0
        select_first!
      end

      def last_page
        @page = @pods.length / pane_height
        select_first!
      end

      def index
        "#{$pastel.cyan(@page+1)}/#{@pods.length / pane_height + 1}"
      end

      # sort nodes by sort function - default is occupancy
      def sort!(method)
        if method == :containers_descending
          @pods.sort!{|a, b| b.pod_occupancy_ratio <=> a.pod_occupancy_ratio }
          select_first!
        end

        if method == :containers_ascending
          @pods.sort!{|a, b| a.pod_occupancy_ratio <=> b.pod_occupancy_ratio }
          select_first!
        end

        if method == :node_name
          @pods.sort!{|a, b| a.name <=> b.name }
          select_first!
        end
      end

      def filter!(pattern)
        @pattern = pattern ? pattern.strip : nil
        select_first!
      end

      # current displayable nodes post filter
      def window
        pods = filter
        if pane_height > pods.length
          pods
        else
          window_idx_last > pods.length ? pods[window_idx_first..-1] : pods[window_idx_first..window_idx_last]
        end
      end

      def window_idx_first
        @page * pane_height
      end

      def window_idx_last
        window_idx_first + pane_height - 1
      end

      def filter
        if @pattern
          @pods.select{|f| /#{@pattern}/.match?(f.plainname) }
        else
          @pods
        end
      end
    end
  end
end
# generates a cli output of the nodes of an eks cluster
module Ui
  module Cards
    class Nodes

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

        def initialize(node, instance)
          @name = node[:name]

          dur = (DateTime.now - DateTime.parse(node[:age]))*60*60*24
          @age = Ui::Util::Duration.human(dur)
          @region = node[:region]
          @pods = [node[:pods].to_i, node[:capacity][:pods].to_i,
                   node[:pods].to_f/node[:capacity][:pods].to_f]
          @volumes = [node[:volume_count].to_i, node[:capacity][:ebs_volumes].to_i,
                      node[:volume_count].to_f / node[:capacity][:ebs_volumes].to_f ]
          @status = node[:status]
          @taints = node[:taints]
          @affinity = node[:labels][:'kubernetes.io/affinity'] || ''
          @version = node[:kubeletVersion]
          @cpu = instance[:cpu] || 0
          @disk = instance[:disk] || 0
          @mem = instance[:memory] || 0
          @selected = false
        end

        def select!
          # puts "selected #{@name}"
          @selected = true
        end

        def deselect!
          @selected = false
        end

        def selected?
          @selected
        end

        # render an ansi pod occupancy string for the node
        def pods
          s = format('%d/%d', @pods[0], @pods[1])
          if  @pods[2] > 0.9
            $pastel.red(s)
          elsif @pods[2] > 0.8
            $pastel.yellow(s)
          else
            s
          end
        end

        def to_s
          @name
        end

        def name
          if @selected
            $pastel.white.bold(@name)
          else
            @name
          end
        end

        def pod_occupancy_ratio
          @pods[2]
        end

        # render an ansi volume occupation string for the node
        def volumes
          s = format('%d/%d', @volumes[0], @volumes[1])
          if  @volumes[2] > 0.9
            $pastel.red s
          elsif @volumes[2] > 0.8
            $pastel.yellow s
          else
            s
          end
        end

        # render an ansi status string for the node
        def status
          if @status['Ready'] != 'True'
            $pastel.red 'X'
          elsif @status['MemoryPressure'] != 'False'
            $pastel.yellow 'Mem'
          elsif @status['DiskPressure'] != 'False'
            $pastel.yello 'Dsk'
          elsif @status['PIDPressure'] != 'False'
            $pastel.yellow 'Pid'
          else
            'Ok'
          end
        end

        # report on node taints
        def taints
          res = if @taints&.any?{|s| s.start_with?('NodeWithImpaired') }
                  $pastel.yellow 'Impaired'
                elsif @taints&.any?{|s| s.end_with?('PreferNoSchedule') }
                  $pastel.cyan 'PrefNoSchedule'
                elsif @taints&.any?{|s| s.end_with?('NoSchedule') }
                  $pastel.red 'NoSchedule'
                else
                  ''
                end
          res
        end

        # report on any affinity label that's been set
        def affinity
          if @affinity == 'monitoring'
            $pastel.bright_cyan @affinity
          else
            @affinity
          end
        end

        def threshold(v, thresholds = { red: 90, yellow: 75, bold: 50})
          if v > thresholds[:red]
            $pastel.bold.on_red v.to_s
          elsif v > thresholds[:yellow]
            $pastel.bright_yellow v.to_s
          elsif v > thresholds[:bold]
            $pastel.bright_white v.to_s
          else
            v.to_s
          end
        end

        # render cpu as a unicode glyph
        def cpu
          '%s%%' % threshold(@cpu)
        end

        # render cpu as a unicode glyph
        def disk
          '%s%%' % threshold(@disk)
        end

        # render cpu as a unicode glyph
        def mem
          '%s%%' % threshold(@mem)
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

      class TotalRow < Row
        def initialize(node)
          @name = "Total Nodes: #{node[:nodes]}"
          @age = ''
          @region = ''
          @pods = [node[:current_pods].to_i, node[:max_pods].to_i,
                   node[:current_pods].to_f/node[:max_pods].to_f]
          @volumes = [node[:current_volumes].to_i, node[:max_volumes].to_i,
                      node[:current_volumes].to_f / node[:max_volumes].to_f ]
          @taints = []
          @affinity = ''
          @version = ''
        end

        def cpu
          ''
        end

        def mem
          ''
        end

        def disk
          ''
        end

        def status
          ''
        end
      end

      def initialize(client, instances, context)
        @context = context
        @model = Model::Nodes.new(client)
        @instances = instances
        @columns = [
          [:name,     45, :left],
          [:age,      10],
          [:region,   15],
          [:pods,     9],
          [:volumes,  9],
          [:status,   7],
          [:taints,   15],
          [:affinity, 15],
          [:version,  25],
          [:cpu,      4],
          [:mem,      4],
          [:disk,     5]
        ].map { |e| Column.new(*e) }.freeze
        @nodes = []
        @selected = -1
        @summary = {}
        @dt = Time.now
      end

      def refresh(fetch=true, order)
        reload! if fetch
        sort!(order)

        @dt = Time.now
        select_first! unless selected
      end

      # sort nodes by sort function - default is occupancy
      def sort!(method = :pods_descending)
        if method == :pods_descending
          @nodes.sort!{|a, b| b.pod_occupancy_ratio <=> a.pod_occupancy_ratio }
        end

        if method == :pods_ascending
          @nodes.sort!{|a, b| a.pod_occupancy_ratio <=> b.pod_occupancy_ratio }
        end
      end

      # reload upstream data
      def reload!
        cwi = @instances.instances
        t_n = @model.nodes
        @nodes = t_n.map { |node| Row.new(node, cwi ? cwi[node[:name]] : {} )  }
        @summary = {
          current_pods: t_n.inject(0) { |sum, n| sum + n[:pods].to_i },
          max_pods: t_n.inject(0) { |sum, n| sum + n[:capacity][:pods].to_i },
          current_volumes: t_n.inject(0)  { |sum, n| sum + n[:volume_count].to_i },
          max_volumes: t_n.inject(0) { |sum, n| sum + n[:capacity][:ebs_volumes].to_i },
          nodes: t_n.size
        }
        select_first!
      end

      def render_header
        @columns.collect(&:title).join('') << "\n"
      end

      def render_lines
        @nodes.collect do |node|
          node.render(@columns)
        end.join("\n") << "\n"
      end

      def render_summary
        TotalRow.new(@summary).render(@columns)
      end

      def render
        output = render_header
        output << render_lines
        output << render_summary
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      # get the currently selected row
      def selected
        @nodes.any?(&:selected?) ? @nodes.select(&:selected?).first : nil
      end

      def select!
        @nodes[@selected].select!
      end

      # reset all node selection flags to false
      def clear_selection!
        @nodes.each(&:deselect!)
      end

      # return true if the next node was selected, false otherwise
      def select_next!
        if selected && @selected < @nodes.length - 1
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
        @nodes[@selected].select!
      end
    end
  end
end
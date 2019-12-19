# generates a cli output of the nodes of an eks cluster
class NodeReport

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
      empty = ' ' * (width - source.uncolorize.length)
      "#{empty}#{source}"
    end

    def ljust(source)
      empty = ' ' * (width - source.uncolorize.length)
      "#{source}#{empty}"
    end
  end

  # models a row in the report
  class Row
    # attributes that don't match a column name won't be rendered
    # attr_reader :node, :region, :version
    attr_reader :name, :region, :version

    def initialize(node)
      @name = node[:name]
      @region = node[:region]
      @pods = [node[:pods].to_i, node[:capacity][:pods].to_i,
               node[:pods].to_f/node[:capacity][:pods].to_f]
      @volumes = [node[:volume_count].to_i, node[:capacity][:ebs_volumes].to_i,
                  node[:volume_count].to_f / node[:capacity][:ebs_volumes].to_f ]
      @status = node[:status]
      @taints = node[:taints]
      @affinity = node[:labels][:'kubernetes.io/affinity'] || ''
      @version = node[:kubeletVersion]
    end

    # render an ansi pod occupancy string for the node
    def pods
      s = format('%d/%d', @pods[0], @pods[1])
      if  @pods[2] > 0.9
        s.red
      elsif @pods[2] > 0.8
        s.yellow
      else
        s
      end
    end

    # render an ansi volume occupation string for the node
    def volumes
      s = format('%d/%d', @volumes[0], @volumes[1])
      if  @volumes[2] > 0.9
        s.red
      elsif @volumes[2] > 0.8
        s.yellow
      else
        s
      end
    end

    # render an ansi status string for the node
    def status
      if @status['Ready'] != 'True'
        'X'.red
      elsif @status['MemoryPressure'] != 'False'
        'Mem'.yellow
      elsif @status['DiskPressure'] != 'False'
        'Dsk'.yellow
      elsif @status['PIDPressure'] != 'False'
        'Pid'.yellow
      else
        'Ok'
      end
    end

    # report on node taints
    def taints
      res = if @taints&.any?{|s| s.start_with?('NodeWithImpaired') }
              'Impaired'.yellow
            elsif @taints&.any?{|s| s.end_with?('PreferNoSchedule') }
              'PrefNoSchedule'.cyan
            elsif @taints&.any?{|s| s.end_with?('NoSchedule') }
              'NoSchedule'.red
            else
              ''
            end
      res
    end

    # report on any affinity label that's been set
    def affinity
      if @affinity == 'monitoring'
        @affinity.cyan.bold
      else
        @affinity
      end
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
      @region = ''
      @pods = [node[:current_pods].to_i, node[:max_pods].to_i,
               node[:current_pods].to_f/node[:max_pods].to_f]
      @volumes = [node[:current_volumes].to_i, node[:max_volumes].to_i,
                  node[:current_volumes].to_f / node[:max_volumes].to_f ]
      @taints = []
      @affinity = ''
      @version = ''
    end

    def status
      ''
    end
  end

  def initialize(nodes)
    @nodes = nodes.map { |node| Row.new(node) }
    @summary = {
      current_pods: nodes.inject(0) { |sum, n| sum + n[:pods].to_i },
      max_pods: nodes.inject(0) { |sum, n| sum + n[:capacity][:pods].to_i },
      current_volumes: nodes.inject(0)  { |sum, n| sum + n[:volume_count].to_i },
      max_volumes: nodes.inject(0) { |sum, n| sum + n[:capacity][:ebs_volumes].to_i },
      nodes: nodes.size
    }

    @columns = [
      [:name,     50, :left],
      [:region,   15],
      [:pods,     10],
      [:volumes,  10],
      [:status,   10],
      [:taints,   20],
      [:affinity, 20],
      [:version,  25],
    ].map { |e| Column.new(*e) }.freeze
  end

  def render_header
    @columns.collect(&:title).join('') << "\n"
  end

  def render_lines
    @nodes.map do |node|
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

end
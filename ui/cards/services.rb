# generates a cli output of the services in an eks cluster
module Ui
  module Cards
    class Services < Base

      # models a row in the report
      class Row < Ui::Pane::SelectableRow
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :region, :color, :namespace, :selector, :ip, :type, :age, :app

        def initialize(service, color)
          @name       = service[:name]
          @namespace  = service[:namespace]
          # @app        = service[:app]
          # @selector   = service[:selector]
          @ip         = service[:ip]
          @type       = service[:type]
          @ports      = service[:ports]
          @load_balancer = service[:load_balancer] || service[:external_name]

          @color = color

          dur = (DateTime.now - DateTime.parse(service[:age]))*60*60*24

          @age = Ui::Util::Duration.human(dur)
        end

        def ports
          @ports && @ports.length > 30 ? "#{@ports[0..27]}.." : @ports
        end

        def load_balancer
          @load_balancer && @load_balancer.length > 50 ? "#{@load_balancer[0..47]}..." : @load_balancer
        end

        def rejigger(columns)
          columns.each do |column|
            m = column.name
            v = send(m)
            column.rejigger(color.strip(v).length + 2) if v
          end
        end

        def selected?
          selected
        end

        def to_s
          @name
        end

        def name
          if selected?
            color.white.bold(@name) + color.bold.yellow(">")
          else
            @name
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

      def initialize(client, context)
        @context = context
        @model = Model::Services.new(client)
        @columns = [
          [:name,     20, :left],
          [:namespace, 15, :left],
          # [:app,      15, :left],
          # [:selector, 15, :left],
          [:type, 15, :left],
          [:ip, 15, :left],
          [:ports, 30, :left],
          [:load_balancer, 40, :left]
        ].map { |e| Ui::Layout::Column.new(*e) }.freeze

        @services = []
        @pane = Ui::Pane.new(@services, TTY::Screen.height - 5)
        @summary = {}
        @pattern = ''

        @dt = Time.now
      end

      def refresh(fetch=true, order)
        reload! if fetch
        sort!(order)

        @pane.update!(@services) if fetch
        @pane.first_row! if fetch

        @dt = Time.now
      end

      # sort nodes by sort function - default is occupancy
      def sort!(method)
        if method == :service_name
          @pane.sort!{|a, b| a.name <=> b.name }
          @pane.first_row!
        end
      end

      def filter!(pattern)
        @pattern = pattern
        @pane.filter! { |f| /#{@pattern}/.match f.name }
      end

      # reload upstream data
      def reload!
        t_n = @model.services
        @services = t_n.map do |node|
          r = Row.new(node, @pane.color)
          r.rejigger(@columns)
          r
        end
      end

      def render_header
        @pane.color.bold.white(@columns.collect(&:title).join('') << "\n")
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
    end
  end
end
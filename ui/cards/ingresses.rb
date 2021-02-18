# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Ingresses < Base
      # models a row in the report
      class Row < Ui::Pane::SelectableRow
        # attributes that don't match a column name won't be rendered
        # attr_reader :node, :region, :version
        attr_reader :namespace, :name, :loadbalancer, :color

        def initialize(ingress, color)
          @color = color
          @name = ingress[:name]
          @namespace = ingress[:namespace]
          @in = ingress[:ingress]
          @status = ingress[:status]
          @age    = ingress[:creationTimestamp]
          @loadbalancer = ingress[:loadbalancer]
        end

        def rejigger(columns)
          columns.each do |column|
            m = column.name
            v = send(m)
            column.rejigger(color.strip(v).length + 1) if v
          end
        end

        def ingress
          return color.yellow('public nginx') if @in == 'ingress-controller-public-nginx'
          return 'private nginx' if @in == 'ingress-controller-internal-nginx'

          'unknown'
        end

        def status
          @status == :active ? 'Active' : color.yellow('Inactive')
        end

        # layout columns
        def render(columns)
          output = ''
          columns.each do |column|
            m = column.name
            output << if m == :name && @selected
                        column.render(color.white.bold(@name) + color.bold.yellow('>'))
                      else
                        column.render(send(m))
                      end
          end
          output
        end
      end

      attr_reader :node, :columns

      def initialize(client)
        # @context = context
        @model = Model::Ingresses.new(client)
        @columns = [
          [:name, 30, :left],
          [:namespace, 20, :left],
          [:ingress, 20, :left],
          [:status, 7, :left],
          [:loadbalancer, 40, :left]
        ].map { |e| Ui::Layout::Column.new(*e) }.freeze
        @ingresses = []
        @pane = Ui::Pane.new(@ingresses, pane_height)
        @dt = Time.now
        @pattern = ''
      end

      # set the list of pods to render

      def refresh(fetch, _order = :default)
        reload! if fetch
        @pane.update!(@ingresses) if fetch
        @pane.first_row! if fetch

        @dt = Time.now
      end

      # reload upstream data
      def reload!
        @ingresses = @model.ingresses.map do |ingress|
          r = Row.new(ingress, @pane.color)
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
        @pane.sort! { |a, b| a.name <=> b.name } if method == :ingress_name
      end

      def filter!(pattern)
        @pattern = pattern
        @pane.filter! { |ingress| /#{@pattern}/.match?(ingress.name) }
      end
    end
  end
end

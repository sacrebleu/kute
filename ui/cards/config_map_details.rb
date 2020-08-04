# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class ConfigMapDetails

      attr_reader :map

      def initialize(client)
        @client = client
        @model = Model::ConfigMaps.new(client)
        @dt = Time.now
        @map = nil
        @name = nil
        @namespace = nil
      end

      def color
        @color ||= Pastel.new
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(row)
        # pp "ROW: #{row}"
        # pp row.name, row.namespace
        @name = row.name
        @namespace = row.namespace
      end

      def height
        @height ||= (TTY::Screen.height - 4)
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        # pp "in reload: [#{@namespace}/#{@name}]"
        @map = @model.describe(@name, @namespace)
        # pp @map

        data = ["No Data in this configmap"]
        data = map.data.to_h&.values&.first&.lines if map.data
        @labels = map.metadata.labels.to_h

        @pane = Ui::Util::DataPane.new(TTY::Screen.width, height - (@labels.values.length + 2), data)
        @pane.first
      end

      def render

        s = <<~DATA
        #{color.cyan(@namespace)}/#{color.blue.bold(@name)}: [ConfigMap]
        labels:
          #{@labels.map{|k,v| "#{k}=#{v}" }.join("\n  ") }
        #{"-" * (TTY::Screen.width - 5)}
        #{@pane.values.join}
        DATA
        # should contain annotations, a divider, then the config map body in the remaining space.
        # pp s
        s
      end

      # next page
      def next_page
        @pane.next
      end

      # previous page
      def previous_page
        @pane.previous
      end

      # first page
      def first_page
        @pane.first
      end

      def last_page
        @pane.last
      end

      def index
        @pane.display_page
      end
    end
  end
end
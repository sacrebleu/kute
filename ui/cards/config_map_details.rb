# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class ConfigMapDetails < Base

      attr_reader :map, :log_pane

      def initialize(client)
        @client = client
        @model = Model::ConfigMaps.new(client)
        @dt = Time.now
        @map = nil
      end

      def color
        @color ||= Pastel.new
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(map)
        @map = map

        data = ["No Data in this configmap"]
        data = map.data.to_h&.values&.first&.lines if map.data

        # TODO make this also contain a window showing annotations etc.  more useful.
        @pane = Ui::Util::DataPane.new(TTY::Screen.width, height)
        data.each {|d| @pane << d }
        @pane.first
      end

      def height
        @height ||= (TTY::Screen.height - 4)
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        self.for(@map)
      end

      def render
        # should contain annotations, a divider, then the config map body in the remaining space.
        @pane.values.join
      end

      # return true if the next node was selected, false otherwise
      def select_next!; end

      # return true if the previous node was selected, false otherwise
      def select_previous!; end

      # select the first node in the current node ordering
      def select_first!;  end
    end
  end
end
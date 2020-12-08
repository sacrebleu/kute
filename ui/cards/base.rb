module Ui
  module Cards
    class Base
      attr_reader :pane

      # time of the last data refresh
      def last_refresh
        @dt
      end

      # get the currently selected row
      def selected
        pane.selected
      end

      # return true if the next node was selected, false otherwise
      def select_next!
        pane.next_row!
      end

      # return true if the previous node was selected, false otherwise
      def select_previous!
        pane.previous_row!
      end

      # select the first node in the current node ordering
      def select_first!
        pane.first_row!
      end

      # next page
      def next_page
        pane.next!
      end

      # previous page
      def previous_page
        pane.previous!
      end

      # first page
      def first_page
        pane.first!
      end

      def last_page
        pane.last!
      end

      def index
        pane.display_page
      end

      def _rj(s, w)
        Ui::Layout::Justifier.rjust(s, w)
      end

      def _lj(s, w)
        Ui::Layout::Justifier.ljust(s, w)
      end
    end
  end
end

module Ui
  # needs a rendering thread and an event handling thread.
  # rewrite.
  module Controller
    # base ui class for rendering
    class Base
      attr_reader :reader, :app

      def initialize(console)
        @app = console
        @buffer = ""
        @reader = TTY::Reader.new
      end

      def color
        @pastel ||= Pastel.new
      end

      def register
        @reader.on(:keypress) { |event| handle(event) unless event.nil? }
      end

      def deregister
        begin
          @reader.send(:local_registrations).clear
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
        end
      end

      def spin_start
        @spinner = TTY::Spinner.new("[#{color.green($settings[:profile])}] #{color.cyan(@app.context['name'])} :spinner " ,
                                    hide_cursor: true, clear: false, success_mark: '')
        @spinner.auto_spin
      end

      def spin_stop
        @spinner.success
      end

      def cursor
        @cursor ||= TTY::Cursor
      end

      def width
        TTY::Screen.width
      end

      def height
        TTY::Screen.height
      end

      #
      def pane_height
        TTY::Screen.height - 2
      end

      # redraw the screen
      def refresh(f, order = :default)
        print cursor.clear_screen
        c_topleft
        spin_start

        @buffer = Concurrent::Promises.future do
          begin
            model.refresh(f, order)
            c = render_model
            spin_stop
            c_goto(0, 2)
            c
          rescue => e
            spin_stop
            puts e.message
            puts e.backtrace.join("\n") if $settings[:verbose]
            raise e
          end
        end

        print @buffer.value(timeout=15)

        c_bottomrighttext(render_refresh_time)

        c_bottomleft

        reader.read_line("#{color.on_blue("[#{color.bold.cyan(@app.current_view)}]")} #{prompt} #{color.on_red("[#{color.bold('q')}uit]")}")
      end

      def c_goto(x,y)
        print cursor.column(x)
        print cursor.row(y)
      end

      # move cursor to top left
      def c_topleft
        print cursor.column(0)
        print cursor.row(0)
      end

      # move cursor to bottom left
      def c_bottomleft
        print cursor.column(0)
        print cursor.row(height)
      end

      # place something at the bottom right (typically refresh time)
      def c_bottomrighttext(str)
        print cursor.row(height)
        print cursor.column(width - str.length)
        print str
      end

      # handle keypress
      def handle(event)
        if event.value == 'q'
          puts "Exiting"
          c_topleft
          print cursor.clear_screen
          exit(1)
        end
      end

      def taint!
        @tainted = true
        refresh(false)
      end

      def untaint!
        @tainted = false
      end

      def tainted?
        @tainted
      end

      def done?
        @done
      end

      def done!
        @done = true
      end

      def reset!
        @done = false
      end

      # main render loop
      def render
        refresh(true)
        until done? do
          sleep(100) until tainted?
          untaint!
          refresh(false)
        end
      end
    end
  end
end
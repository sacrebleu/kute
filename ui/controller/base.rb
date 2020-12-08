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
        @reader = console.reader
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
        @spinner = TTY::Spinner.new("kute-#{VERSION}> [#{color.green($settings[:profile])}] #{color.cyan(@app.context['name'])} :spinner " ,
                                    hide_cursor: true, clear: false, success_mark: '')
        @spinner.auto_spin
      end

      def spin_stop
        @spinner.success
      end

      def cursor
        @cursor ||= TTY::Cursor
      end

      def go_nodes
        app.select(:nodes)
        done!
      end

      def go_pods
        app.select(:pods)
        done!
      end

      def go_generators
        app.select(:generators)
        done!
      end

      def go_services
        app.select(:services)
        done!
      end

      def go_config_maps
        app.select(:config_maps)
        done!
      end

      def go_ingresses
        app.select(:ingresses)
        done
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

        reader.read_line(top_prompt)
      end

      def top_prompt
        [
          color.on_blue("[#{display_view}]"),
          prompt,
          "[#{color.magenta("#{color.bold('r')}efresh")}]",
          "[#{color.bold.red("#{color.white('q')}uit")}]"
        ].join(' ')
      end

      def display_view
        color.bold.cyan(@app.current_view.to_s.split('_').map(&:capitalize).join(' '))
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
        if event.value == 'r'
          puts "Refresh"
          refresh(true)
          taint!
          return
        end

        if event.value == 'q'
          puts "Exiting"
          c_topleft
          print cursor.clear_screen
          exit(1)
        end

        if event.value == 'p'
          go_pods
          return
        end

        if event.value == 'n'
          go_nodes
          return
        end

        if event.value == 's'
          go_services
          return
        end

        if event.value == 'g'
          go_generators
          return
        end

        if event.value == 'i'
          go_ingresses
          return
        end

        if event.value == 'm'
          go_config_maps
          return
        end

        if event.key.name == :space
          model.next_page
        end

        if event.value == 'b'
          model.previous_page
        end

        if event.value == '^'
          model.first_page
        end

        if event.value == '$'
          model.last_page
        end

        if event.value == '*'
          model.filter! nil
        end

        if event.key.name == :up
          model.select_previous!
          refresh(false)
        end

        if event.key.name == :down
          model.select_next!
          refresh(false)
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
      def render(refresh = true)
        refresh(refresh)
        until done? do
          sleep(100) until tainted?
          untaint!
          refresh(false)
        end
      end
    end
  end
end

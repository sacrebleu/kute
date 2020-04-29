# main model for the kute ui - will handle events, delegate to the correct renderer etc.
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-prompt'

module Ui
  class Controller
    attr_reader :context

    def initialize(context)
      @context = context
      @cards = {}
    end

    def nodes=(card)
      @cards[:nodes] = Nodes.new(self, card)
    end

    def select(key)
      card = @cards[key] || @cards[:help]
      card.render
    end
  end

  # base ui class for rendering
  class Base
    attr_reader :reader

    def initialize(controller)
      @controller = controller
      @reader = TTY::Prompt.new
      @buffer = ""
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

    # redraw the screen
    def refresh
      @buffer = Concurrent::Promises.future do
        c = load_content
        send(:spin_stop)
        c_goto(0, 2)
        c
      end

      print cursor.clear_screen
      c_topleft
      send(:spin_start)

      print @buffer.value(timeout=5)

      c_bottomrighttext(render_refresh_time)

      c_bottomleft
      res = send(:prompt)
      handle(res)
    end

    def load_content
      send(:refresh_model)
      send(:render_model)
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
      # print event
      if event == :quit
        puts "Exiting"
        exit(1)
      end
    end

    # main render loop
    def render
      refresh
      loop do
        refresh
      end
    end
  end

  # ui to render node information
  class Nodes < Base
    attr_reader :model

    def initialize(controller, model)
      super(controller)
      @model = model
      # @spinner =
    end

    def spin_start
      @spinner = TTY::Spinner.new("[:spinner]> #{$pastel.cyan(@controller.context['name'])} [#{$pastel.green($settings[:profile])}]",
                                  hide_cursor: true, clear: false)
      @spinner.auto_spin
    end

    def spin_stop
      @spinner.stop
    end

    # render the node report
    def render_model
      # puts "foo"
      model.render
    end

    # when did we last refresh
    def render_refresh_time
      "Refresh: #{model.last_refresh.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    # node commands
    def prompt
      reader.expand('Commands: ', auto_hint: false, ) do |q|
        q.choice key: 'w', name: 'Fetch Cloudwatch metrics' do :cloudwatch end
        q.choice key: 'r', name: 'Refresh nodes' do :refresh end
        q.choice key: 'a', name: 'Filter by annotation' do :annotations end
        q.choice key: 'l', name: 'Filter by labels' do :labels end
        q.choice key: 'u', name: 'Show usage' do :usage end
        q.choice key: 'q', name: 'Quit' do :quit end
      end
    end

    # node keypresses
    def handle(evt)
      super(evt)
      if :cloudwatch == evt
        puts "Fetching cloudwatch metrics..."
      end

      if :refresh == evt
        refresh_model
      end
    end

    # reload the node report
    def refresh_model
      model.refresh
    end
  end
end
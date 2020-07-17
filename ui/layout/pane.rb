# layout module
module Layout
  # paginator because I keep having to reimplement this and keep making bugs
  class Pane

    attr_reader :pages, :rows

    # generate a new paginator of length data.length and rows h
    def initialize(data, h = TTY::Screen.height)
      @data = data
      @rows = h
      @filtered = data
      # @view = []
      @page = 1
      @pages = (@filtered.length - 1) / @rows + 1

      @selected = nil
    end

    # recalculate all internal values
    def recalculate!
      @pages = (@filtered.length - 1) / @rows + 1
      @page = (@selected / rows) + 1 if @selected
      @page = 1 if @page > @pages # reset our page index
    end

    # get current view
    def view
      i = (@page - 1) * rows
      j = @page * rows > filtered_items ? filtered_items - 1 : @page * rows - 1

      @filtered[i..j]
    end

    # display page n/N
    def display_page
      "page #{@page}/#{@pages}"
    end

    # get the full item list
    def items
      @data.length
    end

    # get filtered data list
    def filtered_items
      @filtered.length
    end

    # number of items to render per page
    def items_per_page
      @rows
    end

    # apply a filter
    def filter!(&block)
      @filtered = @data.select { |e| yield(e) } if block_given?
      @filtered = @data unless block_given?
      recalculate!
    end

    # row level methods for interacting with data items in a particular viewset
    # select the next item in the data list
    def next_row!
      step { @selected += 1 if @selected < @filtered.length }
    end

    # select the previous item in the data list
    def previous_row!
      step { @selected -= 1 if @selected.positive? }
    end

    def selected
      return view[@selected % rows] if @selected && view[@selected % rows]

      nil
    end

    # select the first item in the data list
    def first_row!
      step { @selected = 0 }
      # selected.deselect! if selected
      # @selected = 0
      # selected.select! if selected
    end

    # go directly to a specific row in the view.  row is 1-index not 0-index
    def goto_row!(row)
      step { @selected = row - 1 if row.positive? && row <= filtered_items }
    end

    def last_row!
      # @selected = items_per_page - 1
      step { @selected = items_per_page - 1 }
    end

    private
    def step(&block)
      selected.deselect! if selected
      yield if block_given?
      recalculate!
      selected.select! if selected
    end

    public

    # page navigation methods for scrolling the viewing window over the dataset

    # select the next page
    def next!
      @page += 1 if @page < @pages
    end

    def goto!(page)
      @page = page if page&.positive? && page <= @pages
    end

    # select the previous page
    def previous!
      @page -= 1 if @page > 1
    end

    # select the first page
    def first!
      @page = 1
    end

    # select the first page
    def last!
      @page = @pages
    end
  end

end
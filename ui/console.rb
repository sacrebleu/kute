# main model for the kute ui - will handle events, delegate to the correct renderer etc.
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-prompt'

require_relative 'util/duration'


module Ui
  class Console
    attr_reader :context
    attr_reader :poke

    def initialize(context)
      @context = context
      @selected = :nodes
      @cards = {}
    end

    def nodes=(card)
      @cards[:nodes] = Ui::Controller::Nodes.new(self, card)
    end

    def pods=(card)
      @cards[:pods] = Ui::Controller::Pods.new(self, card)
    end

    def pods
      @cards[:pods]
    end

    def nodes
      @cards[:nodes]
    end

    def select(key)
      @selected = @cards[key] ? key : :help
      render
    end

    # call through to the card's render method
    def render
      @cards[@selected].reset!
      @cards[@selected].render
    end

  end
end
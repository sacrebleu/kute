# main model for the kute ui - will handle events, delegate to the correct renderer etc.
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-prompt'

require_relative 'util/duration'


module Ui
  class Console
    attr_reader :context

    def initialize(clients, context, instances)
      @context = context
      client = clients.first
      @cards = {
        nodes: Ui::Controller::Nodes.new(self, Ui::Cards::Nodes.new(client, instances)),
        pods: Ui::Controller::Pods.new(self, Ui::Cards::Pods.new(client)),
        pod_details: Ui::Controller::PodDetails.new(self, Ui::Cards::Pod.new(client)),
        services: Ui::Controller::Services.new(self, Ui::Cards::Services.new(client)),
        service_details: Ui::Controller::ServiceDetails.new(self, Ui::Cards::Service.new(client)),
        ingresses: Ui::Controller::Ingresses.new(self, Ui::Cards::Ingresses.new(clients.last)),
        ingress_details: Ui::Controller::IngressDetails.new(self, Ui::Cards::Ingress.new(clients.last))
      }
      @selected = :nodes
    end

    def pods
      @cards[:pods]
    end

    def nodes
      @cards[:nodes]
    end

    def pod_details
      @cards[:pod_details]
    end

    def service_details
      @cards[:service_details]
    end

    def ingresses
      @cards[:ingresses]
    end

    def ingress_details
      @cards[:ingress_details]
    end

    def current_view
      @selected.capitalize
    end

    def select(key)
      @cards[@selected]&.deregister
      @selected = @cards[key] ? key : :help
      @cards[@selected]&.register
      render
    end

    # call through to the card's render method
    def render
      @cards[@selected].reset!
      @cards[@selected].render
    end
  end
end
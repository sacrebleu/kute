# main model for the kute ui - will handle events, delegate to the correct renderer etc.
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-prompt'

require_relative 'util/duration'


module Ui
  class Console
    attr_reader :context, :logger, :reader

    def initialize(clients, context, instances)
      @context = context
      @reader = TTY::Reader.new
      client = clients.first
      @cards = {
        nodes: Ui::Controller::Nodes.new(self, Ui::Cards::Nodes.new(client, instances)),
        pods: Ui::Controller::Pods.new(self, Ui::Cards::Pods.new(client)),
        pod_details: Ui::Controller::PodDetails.new(self, Ui::Cards::Pod.new(client)),
        services: Ui::Controller::Services.new(self, Ui::Cards::Services.new(client)),
        service_details: Ui::Controller::ServiceDetails.new(self, Ui::Cards::Service.new(client)),
        ingresses: Ui::Controller::Ingresses.new(self, Ui::Cards::Ingresses.new(clients.last)),
        ingress_details: Ui::Controller::IngressDetails.new(self, Ui::Cards::Ingress.new(clients.last)),
        config_maps: Ui::Controller::ConfigMaps.new(self, Ui::Cards::ConfigMaps.new(client)),
        map_details: Ui::Controller::ConfigMapDetails.new(self, Ui::Cards::ConfigMapDetails.new(client))
      }
      @selected = :nodes
      @render = nil
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

    def config_maps
      @cards[:config_maps]
    end

    def map_details
      @cards[:map_details]
    end

    def current_view
      @selected.capitalize
    end

    def select(key,refresh = true)
      @cards[@selected]&.deregister
      @selected = @cards[key] ? key : :help
      @cards[@selected]&.register
      render(refresh)
    end

    # call through to the card's render method
    def render(refresh)
      @cards[@selected].reset!
      @cards[@selected].render(refresh)
    end
  end
end
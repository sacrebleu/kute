# main model for the kute ui - will handle events, delegate to the correct renderer etc.
require 'tty-cursor'
require 'tty-screen'
require 'tty-reader'
require 'tty-prompt'

require_relative 'util/duration'


module Ui
  class Console
    attr_reader :context, :logger, :reader

    def initialize(version_manager, context, instances)
      @context = context
      @reader = TTY::Reader.new
      @cards = {
        nodes: Ui::Controller::Nodes.new(self, Ui::Cards::Nodes.new(version_manager, instances)),
        pods: Ui::Controller::Pods.new(self, Ui::Cards::Pods.new(version_manager)),
        pod_details: Ui::Controller::PodDetails.new(self, Ui::Cards::Pod.new(version_manager)),
        services: Ui::Controller::Services.new(self, Ui::Cards::Services.new(version_manager)),
        service_details: Ui::Controller::ServiceDetails.new(self, Ui::Cards::Service.new(version_manager)),
        ingresses: Ui::Controller::Ingresses.new(self, Ui::Cards::Ingresses.new(version_manager)),
        ingress_details: Ui::Controller::IngressDetails.new(self, Ui::Cards::Ingress.new(version_manager)),
        config_maps: Ui::Controller::ConfigMaps.new(self, Ui::Cards::ConfigMaps.new(version_manager)),
        map_details: Ui::Controller::ConfigMapDetails.new(self, Ui::Cards::ConfigMapDetails.new(version_manager)),
        generators: Ui::Controller::Generators.new(self, Ui::Cards::Generators.new(version_manager)),
        generator_details: Ui::Controller::GeneratorDetails.new(self, Ui::Cards::GeneratorDetails.new(version_manager)),
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

    def generators
      @cards[:generators]
    end

    def generator_details
      @cards[:generator_details]
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
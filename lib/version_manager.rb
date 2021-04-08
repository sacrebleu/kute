# manages API differences across kubernetes versions

class VersionManager
  attr_reader :clients, :version, :auth_options, :endpoint, :mediator

  def initialize(version, endpoint, auth_options)
    @clients = {}
    @version = version
    @auth_options = auth_options
    @endpoint = endpoint

    @resolver =
      if version == '1.13'
        Kubernetes13.new
      else
        Kubernetes.new
      end
  end

  def networking
    @resolver.networking
  end

  def extensions
    @resolver.extensions
  end

  def apps
    @resolver.apps
  end

  def client_for(api, version)
    k = (api == :default ? endpoint : "#{endpoint}/apis/#{api}")
    kv = "#{k}/#{version}"
    clients[kv] ||= Kubeclient::Client.new(
      k,
      version,
      auth_options: auth_options,
      ssl_options: { verify_ssl: OpenSSL::SSL::VERIFY_NONE }
    )
  end

  # delegates
  def method_missing(symbol, *args)
    # pp "symbol: #{symbol}, args: #{args}"
    client = if networking.include?(symbol)
               client_for('networking.k8s.io', 'v1beta1')
             elsif extensions.include?(symbol)
               client_for('extensions', 'v1beta1')
             elsif apps.include?(symbol)
               client_for('apps', 'v1')
             else
               client_for(:default, 'v1')
             end

    if args && !args.empty?
      client.send(symbol, *args)
    else
      client.send(symbol)
    end
  end

  def respond_to_missing?(_method_name, _include_private = false)
    true
  end

  # 1.14+
  class Kubernetes
    def extensions
      @extensions ||= []
    end

    def networking
      @networking ||= %i[
        get_ingresses
        get_ingress
      ]
    end

    def apps
      @apps ||= %i[
        get_deployments
        get_deployment
        get_stateful_sets
        get_stateful_set
        get_daemon_sets
        get_daemon_set
        get_replica_sets
        get_replica_set
      ]
    end

    def respond_to_missing?(_method_name, _include_private = false)
      true
    end
  end

  class Kubernets13 < Kubernetes
    def extensions
      @extension ||= %i[
        get_ingresses
        get_ingress
        get_deploments
        get_deployment
        get_stateful_sets
        get_stateful_set
        get_daemons_sets
        get_daemon_set
        get_replica_sets
        get_replica_set
      ]
    end

    def networking
      @networking ||= []
    end

    def apps
      @apps ||= []
    end
  end
end

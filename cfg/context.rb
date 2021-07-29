# application configuration and settings container
class Context

  attr_reader :cluster_arn
  attr_reader :cluster_name
  attr_reader :region
  attr_reader :profile
  attr_reader :verbose
  attr_reader :cloudwatch
  attr_reader :resource
  attr_reader :name
  attr_reader :server


  def initialize(opts = {})
    @name = opts[:name]
    @region = opts[:region]
    @profile = opts[:profile]
    @verbose = opts[:verbose]
    @cloudwatch = opts[:cloudwatch]
    @resource = opts[:resource]
    @cluster_arn = opts[:cluster_arn]
    @cluster_name = opts[:cluster_name]
    @server = opts[:server]
  end

  alias :selected :resource
end
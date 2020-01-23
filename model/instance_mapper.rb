# frozen_string_literal: true

class InstanceMapper
  attr_reader :cloudwatch, :instances, :cluster_name, :starttime, :endtime, :period

  def initialize(credentials, cluster_name, settings)
    @cloudwatch ||= cw = Aws::CloudWatch::Client.new(credentials: credentials)
    @cluster_name = cluster_name
    @starttime = Time.now - 120
    @endtime   = Time.now
    @period = 60
    @instances = load if settings[:cloudwatch]
  end

  def load
    ec2s = Aws::EC2::Client.new(credentials: credentials).describe_instances(
      filters: [{ name: "tag:kubernetes.io/cluster/#{cluster_name}", values: ['owned'] }]
    )
             .reservations.collect { |r| r.instances.flatten }

    # generate a map of hostname => instance_id
    instance_ids = ec2s.map { |i| i.map { |j| { j.private_dns_name => j.instance_id } } }
                     .flatten
                     .reduce({}, :merge)

    instances = []

    instance_ids.each do |k,v|
      # get cpu utilisation
      cput = cw.get_metric_statistics(
        namespace: 'ContainerInsights', # required
        metric_name: 'node_cpu_utilization', # required
        dimensions: [
          {
            name: 'ClusterName', # required
            value: cluster_name, # required
          },
          {
            name: 'InstanceId',
            value: v
          },
          {
            name: 'NodeName',
            value: k
          }
        ],
        start_time: Time.now - 120, # required
        end_time: Time.now, # required
        period: 60, # required
        statistics: ['Average'] # accepts SampleCount, Average, Sum, Minimum, Maximum
      )

      cput = instance_cpu(v, k)
      memt = instance_memory(v, k)
      dist = instance_disk(v, k)

      instances << { k => {
        cpu: cput.datapoints&.first&.average&.truncate(0) || 0,
        memory: memt.datapoints&.first&.average&.truncate(0) || 0,
        disk: dist.datapoints&.first&.average&.truncate(0) || 0
      } }
    end
    instances.reduce({}, :merge)
  end

  def instance_cpu(instance_id, node_name)
    get_metric 'node_cpu_utilization', instance_id, node_name
  end

  def instance_disk(instance_id, node_name)
    get_metric 'node_filesystem_utilization', instance_id, node_name
  end

  def instance_memory(instance_id, node_name)
    get_metric 'node_memory_utilization', instance_id, node_name
  end

  def get_metric(metric, instance_id, node_name)
    cloudwatch.get_metric_statistics(
      namespace: 'ContainerInsights', # required
      metric_name: metric, # required
      dimensions: [
        {
          name: 'ClusterName', # required
          value: cluster_name, # required
        },
        {
          name: 'InstanceId',
          value: instance_id
        },
        {
          name: 'NodeName',
          value: node_name
        }
      ],
      start_time: starttime, # required
      end_time: endtime, # required
      period: period, # required
      statistics: ['Average'] # accepts SampleCount, Average, Sum, Minimum, Maximum
    )
  end
end

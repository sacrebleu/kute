# generates a cli output of a specific node
module Ui
  module Cards
    class Node < Base
      attr_reader :node

      def initialize(client)
        @client = client
        @model = Model::Nodes.new(client)
        @dt = Time.now
        @selected = -1
        @containers = []
      end

      def color
        @color ||= Pastel.new
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(node)
        @source = node
        reload!
      end

      def next; end

      def previous; end

      def height
        @height ||= (TTY::Screen.height - 2)
      end

      def refresh(fetch, _order = :default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        @node = @model.describe(@source)
      end

      def flag(s, field = nil)
        if s == 'Failed'
          color.bold.red(field || s)
        elsif s == 'Unknown'
          color.bold.red(field || s)
        elsif s == 'Pending'
          color.bold.yellow(field || s)
        else
          color.green(field || s)
        end
      end

      def switch(s, field = nil)
        if s == 'True'
          color.bold.red(field || s)
        else
          color.green(field || s)
        end
      end

      def ratio(v1, v2, thresholds = { warn: 0.75, critical: 0.9 })
        if (v1.to_i / v2.to_f) > thresholds[:critical]
          "#{color.red(v1)}/#{v2}"
        elsif (v1.to_i / v2.to_f) > thresholds[:warn]
          "#{color.yellow(v1)}/#{v2}"
        else
          "#{v1}/#{v2}"
        end
      rescue StandardError => e
        puts e.backtrace.join("\n")
      end

      def remainder_as_percentage(t, a, thresholds = { warn: 0.75, critical: 0.9 })
        ratio = (t.to_i - a.to_i) / t.to_f

        begin
          if ratio > thresholds[:critical]
            color.bold.red(format('%.2d', (ratio * 100.0)))
          elsif ratio > thresholds[:warn]
            color.yellow(format('%.2d', (ratio * 100.0)))
          else
            format('%.d', (ratio * 100.0))
          end
        rescue StandardError => e
          puts e.backtrace.join("\n")
        end
      end

      def render
        node_mem = Ui::Util::Space.memorize(node[:capacity][:memory])
        node_avail_mem = Ui::Util::Space.memorize(node[:available_capacity][:memory])

        space = Ui::Util::Space.binarytohuman(node[:capacity][:ephemeral])
        avail_space = node[:available_capacity][:ephemeral].to_i

        age = Ui::Util::Duration.human(Time.now.to_i - DateTime.parse(node[:age]).to_time.to_i)

        out = <<~DONE
          node:            #{color.bold(node[:name])}          region: #{color.cyan(node[:region])}           version: #{color.yellow(node[:kubeletVersion])}    age: #{age}
          status:          #{switch(node[:status]['MemoryPressure'], 'MemoryPressure')} | #{switch(node[:status]['DiskPressure'], 'DiskPressure')} | #{switch(node[:status]['PIDPressure'], 'PIDPressure')} | #{flag(node[:status]['NodeReady'], 'Ready')}
          affinity:        #{color.cyan(node[:labels][:"kubernetes.io/affinity"])}

          volumes:         #{_rj(ratio(node[:volume_count], node[:capacity][:ebs_volumes]), 8)}
          cpus:            #{_rj(node[:capacity][:cpus], 8)}
          total memory:    #{_rj(Ui::Util::Space.humanize(node_mem), 8)} | avail: #{_rj(Ui::Util::Space.humanize(node_avail_mem), 8)} | used: #{_rj(remainder_as_percentage(node_mem, node_avail_mem), 8)}%
          ephemeral space: #{_rj(Ui::Util::Space.humanize(space), 8)}  | avail: #{_rj(Ui::Util::Space.humanize(avail_space), 8)} | used: #{_rj(remainder_as_percentage(space, avail_space), 8)}%
          pods:            #{_rj(ratio(node[:pods], node[:capacity][:pods]), 8)}

          taints:
        DONE

        node[:taints]&.each do |taint|
          k, v = taint.split(/:/)
          k.gsub!(/=/, '[')
          tag = k.include?('[') ? "#{k}]" : k

          if v == 'NoSchedule'
            v = color.red(v)
          elsif v == 'PreferNoSchedule'
            v = color.cyan(v)
          end

          out << format('%s -> %s', tag, v)
        end

        out
      rescue StandardError => e
        puts e.message
        puts e.backtrace.join("\n")
      end

      def select_next!
        self.next
      end

      def select_previous!
        previous
      end
    end
  end
end

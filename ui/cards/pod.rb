# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Pod

      attr_reader :pod

      def initialize(client, context)
        @context = context
        @model = Model::Pods.new(client)
        @dt = Time.now
        @selected = -1
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(pod)
        @source = pod
        reload!
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        @pod = @model.describe(@source.name, @source.namespace)
      end

      def status
        s = @pod.status.phase
        if s == 'Failed'
          $pastel.bold.red(s)
        elsif s == 'Unknown'
          $pastel.bold.red(s)
        elsif s == 'Pending'
          $pastel.bold.yellow(s)
        else
          s
        end
      end

      def conditions
        pod.status.conditions.map {|c| c[:type] ? "+#{$pastel.green(c[:type].to_s)}" : "-#{pastel.red(c[:type].to_s)}" }.join(' ')
      end

      def _rj(s, w)
        Ui::Layout::Justifier.rjust(s, w)
      end

      def _lj(s, w)
        Ui::Layout::Justifier.ljust(s, w)
      end

      def container_status(cs)
        if cs.state.running
          "#{$pastel.bold.white("Running")} since #{cs.state.running.startedAt} [restarts: #{cs.restartCount}]"
        elsif cs.state.terminated
          if cs.state.terminated.exitCode > 0
            "#{$pastel.bold.red("Terminated")} (#{cs.state.terminated.reason}) at #{cs.state.terminated.finishedAt}"
          else
            "#{$pastel.bold.white("Terminated")} (#{cs.state.terminated.reason}) at #{cs.state.terminated.finishedAt}"
          end
        else
          "#{$pastel.bold.yellow("Waiting")} (#{cs.state.waiting.reason}) [restarts: #{cs.restartCount}]"
        end
      end

      def render
        # row 1 - start time, status, ip, controlled-by
        owr = pod.metadata.ownerReferences&.first || {}

        cnw = [pod.spec.containers.map{|c| c[:name].length }.max + 1, 8].max
        # iw  = pod.spec.containers.map{|c| c[:image].length }.max + 1

        statuses = Hash[pod.status.containerStatuses.map do |cs|
          [cs[:name], cs]
        end
        ]

        cnt = pod.spec.containers.map do |c|
          # name = c[:name][0..cnw-1]
          name = statuses[c[:name]][:ready] ? $pastel.green(c[:name][0..cnw-1]) : $pastel.yellow(c[:name][0..cnw-1])
          s = statuses[c[:name]]

          # state = s[:state].to_h.keys.first
          # since = s[:state][state][:startedAt]

          <<~CONT
          #{_lj(name, cnw)} #{container_status(s)}
          #{_rj('image:', cnw)} #{c[:image]} (pull: #{$pastel.cyan(c[:imagePullPolicy])})
          #{_rj('ports:', cnw)} #{c[:ports]&.map{|p| "#{p[:protocol]}:#{p[:containerPort]}"}&.join(', ')}
          #{_rj('mounts:', cnw)} #{c[:volumeMounts].map{|v| "#{v[:name]} -> #{v[:mountPath]}#{v[:readOnly]?" [ro]":$pastel.yellow(" [w+]")}"}&.join("\n #{_lj(' ', cnw)}")}
          CONT
        end.join("\n")

        generator = owr ? "#{owr[:name]} [#{owr[:kind]}]" : "Unknown"
        w = [generator, pod.spec.schedulerName].collect(&:length).max + 1

        out = <<~DONE
        
          Pod:        #{pod.metadata.namespace}/#{$pastel.white(pod.metadata.name)} [#{$pastel.cyan(pod.status.podIP)}]
          Status:     #{status} [#{conditions}]
          
          Host Node:  #{pod.status.hostIP} (#{$pastel.blue(pod.spec.nodeName)})    
          Generator:  #{_rj(generator, w)}   Service Account: #{pod.spec.serviceAccount}
          Scheduler:  #{_rj(pod.spec.schedulerName, w)}           Restart: #{$pastel.cyan(pod.spec.restartPolicy)}   Grace period: #{$pastel.cyan(pod.spec.terminationGracePeriodSeconds)}s  
        
          labels:     #{pod.metadata.labels.to_h.reject{|k,_| ["pod-template-hash", :version].include?(k)}.map{|k,v| "#{k}=#{$pastel.cyan(v)}"}.join("\n            ")}
          annotate:   #{pod.metadata.annotations.to_h.reject{|k,_| [:"kubernetes.io/psp"].include?(k)}.map{|k,v| "#{k}=#{$pastel.cyan(v)}"}.join("\n            ")}
          tolerate:   #{pod.spec.tolerations.map {|t| "#{t.operator} #{t.key} -> #{$pastel.bold.white(t.effect)} #{t.tolerationSeconds ? "#{t.tolerationSeconds}s" : "" }"}.join("\n            ")}

          containers:
          #{cnt}

        DONE
        out
      end
    end
  end
end
# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class Pod < Base

      attr_reader :pod, :log_pane

      def initialize(client)
        @client = client
        @model = Model::Pods.new(client)
        @dt = Time.now
        @selected = -1
        @log_pane = Ui::LogPane.new
        @container = 0
        @containers = []
      end

      def color
        @color ||= Pastel.new
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(pod)
        @source = pod
        reload!
      end

      def next
        @container = (@container + 1) % @pod.spec.containers.length
      end

      def previous
        @container = (@container - 1) % @pod.spec.containers.length
      end

      def height
        @height ||= (TTY::Screen.height - 2)
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        @pod = @model.describe(@source.name, @source.namespace)
        @containers = @pod.spec.containers.sort_by{ |a| a[:name] }
      end

      def status
        s = @pod.status.phase
        if s == 'Failed'
          color.bold.red(s)
        elsif s == 'Unknown'
          color.bold.red(s)
        elsif s == 'Pending'
          color.bold.yellow(s)
        else
          s
        end
      end

      def conditions
        pod.status.conditions.map {|c| c[:type] ? "+#{color.green(c[:type].to_s)}" : "-#{pastel.red(c[:type].to_s)}" }.join(' ')
      end

      def watch_logs
        @tail = true
        container = @containers[@container]
        s = @client.get_pod_log(@source.name, @source.namespace, {container: container.name, tail_lines: 100})
        s.split("\n").each{ |s| log_pane << s }
      end

      def previous_page
        if @tail
          unwatch_logs
        else
          previous
        end
      end

      def unwatch_logs
        @tail = false
        log_pane.clear
      end

      def container_status(cs)
        if cs.state.running
          "#{color.bold.white("Running")} since #{cs.state.running.startedAt} [restarts: #{cs.restartCount}]"
        elsif cs.state.terminated
          if cs.state.terminated.exitCode > 0
            "#{color.bold.red("Terminated")} (#{cs.state.terminated.reason}) at #{cs.state.terminated.finishedAt}"
          else
            "#{color.bold.white("Terminated")} (#{cs.state.terminated.reason}) at #{cs.state.terminated.finishedAt}"
          end
        else
          "#{color.bold.yellow("Waiting")} (#{cs.state.waiting.reason}) [restarts: #{cs.restartCount}]"
        end
      end

      def render
        if @tail
          log_pane.values.join("\n")
        else

          # row 1 - start time, status, ip, controlled-by
          owr = pod.metadata.ownerReferences&.first || {}

          cnw = [pod.spec.containers.map{|c| c[:name].length }.max + 2, 8].max

          statuses = Hash[pod.status.containerStatuses.map do |cs|
            [cs[:name], cs]
          end
          ]

          cnt = pod.spec.containers.each_with_index.map do |c, i|
            # name = c[:name][0..cnw-1]
            name = statuses[c[:name]][:ready] ? color.green(c[:name][0..cnw-1]) : color.yellow(c[:name][0..cnw-1])
            if i == @container
              name = "#{color.bold.white("*")}#{color.bold(name)}"
            end
            s = statuses[c[:name]]

            <<~CONT
            #{_lj(name, cnw)} #{container_status(s)}
            #{_rj('image:', cnw)} #{c[:image]} (pull: #{color.cyan(c[:imagePullPolicy])})
            #{_rj('ports:', cnw)} #{c[:ports]&.map{|p| "#{p[:protocol]}:#{p[:containerPort]}"}&.join(', ')}
            #{_rj('mounts:', cnw)} #{c[:volumeMounts].map{|v| "#{v[:name]} -> #{v[:mountPath]}#{v[:readOnly]?" [ro]":color.yellow(" [w+]")}"}&.join("\n #{_lj(' ', cnw)}")}
            CONT
          end.join("\n")

          generator = owr ? "#{owr[:name]} [#{color.cyan(owr[:kind])}]" : "Unknown"
          w = [generator, pod.spec.schedulerName].collect(&:length).max + 1

          out = <<~DONE
          
            Pod:        #{pod.metadata.namespace}/#{color.white(pod.metadata.name)} [#{color.cyan(pod.status.podIP)}]
            Status:     #{status} [#{conditions}]
            
            Host Node:  #{pod.status.hostIP} (#{color.blue.bold(pod.spec.nodeName)})    
            Generator:  #{_rj(generator, w)}   Service Account: #{pod.spec.serviceAccount}
            Scheduler:  #{_rj(pod.spec.schedulerName, w)}           Restart: #{color.cyan(pod.spec.restartPolicy)}   Grace period: #{color.cyan(pod.spec.terminationGracePeriodSeconds)}s  
          
            labels:     #{pod.metadata.labels.to_h.reject{|k,_| ["pod-template-hash", :version].include?(k)}.map{|k,v| "#{k}=#{color.cyan(v)}"}.join("\n            ")}
            annotate:   #{pod.metadata.annotations.to_h.reject{|k,_| [:"kubernetes.io/psp"].include?(k)}.map{|k,v| "#{k}=#{color.cyan(v)}"}.join("\n            ")}
            tolerate:   #{pod.spec.tolerations.map {|t| "#{t.operator} #{t.key} -> #{color.bold.white(t.effect)} #{t.tolerationSeconds ? "#{t.tolerationSeconds}s" : "" }"}.join("\n            ")}
  
            containers:
            #{cnt}

          DONE
          out
        end
      end

      def select_next!
        self.next
      end

      def select_previous!
       self.previous
      end
    end
  end
end

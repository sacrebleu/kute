# generates a cli output of the pods belonging to an eks node
module Ui
  module Cards
    class GeneratorDetails

      attr_reader :generator

      def initialize(client)
        @client = client
        @model = Model::Generators.new(client)
        @dt = Time.now
        @selected = -1
      end

      def color
        @color ||= Pastel.new
      end

      # time of the last data refresh
      def last_refresh
        @dt
      end

      def for(gen)
        @source = gen
        reload!
      end

      def height
        @height ||= (TTY::Screen.height - 2)
      end

      def refresh(fetch, order=:default)
        reload! if fetch
        @dt = Time.now
      end

      def reload!
        @generator = @model.describe(@source.name, @source.namespace, @source.resource_type)
      end

      def _rj(s, w)
        Ui::Layout::Justifier.rjust(s, w)
      end

      def _lj(s, w)
        Ui::Layout::Justifier.ljust(s, w)
      end

      def render
        if generator[:kind] == "ReplicaSet"
          ReplicaSet.new(generator, color).render
        end
      end


      def select_next!
        self.next
      end

      def select_previous!
       self.previous
      end
    end

    class Resource
      attr_reader :record, :color
      def initialize(record, color)
        @record = record
        @color = color
      end

      def _rj(s, w)
        Ui::Layout::Justifier.rjust(s, w)
      end

      def _lj(s, w)
        Ui::Layout::Justifier.ljust(s, w)
      end
    end

    class DaemonSet < Resource

    end

    class ReplicaSet < Resource
      def render
        # row 1 - start time, status, ip, controlled-by
        containers = record.spec.template.spec.containers
        cnw = [containers.map{|c| c[:name].length }.max + 2, 8].max

        statuses = record.status

        status = if statuses[:currentNumberScheduled] == statuses[:desiredNumberScheduled] &&
                    statuses[:numberReady] == statuses[:desiredNumberScheduled] &&
                    statuses[:numberAvailable] == statuses[:desiredNumberScheduled]
                   color.bold.green("Ok")
                 elsif statuses[:numberReady] == 0 || statuses[:numberAvailable] == 0
                   color.bold.red("Critical")
                 else
                   color.bold.yellow("Partially Ready")
                 end


        cnt = containers.map do |c|
          name = c[:name]
          s = <<~CONT
            #{_lj(color.bold(name), cnw)}
            #{_rj('image:', cnw)} #{c[:image]} (pull: #{color.cyan(c[:imagePullPolicy])})
            #{_rj('ports:', cnw)} #{c[:ports]&.map{|p| "#{p[:protocol]}:#{p[:containerPort]}"}&.join(', ')}
          CONT
            s << "#{_rj('mounts:', cnw)} #{c[:volumeMounts].map{|v| "#{v[:name]} -> #{v[:mountPath]}#{v[:readOnly]?" [ro]":color.yellow(" [w+]")}"}&.join("\n #{_lj(' ', cnw)}")}" if c[:volumeMounts]
        end.join("\n")

        ts = record.spec.template.spec

        w = "#{record.metadata.namespace}/#{record.metadata.name}".length

        out =<<~DONE
        
            Replica Set: #{record.metadata.namespace}/#{color.white(record.metadata.name)}  Status: #{status} 
            Scheduler:   #{_lj(color.cyan(ts.schedulerName), w)}  Restart: #{color.cyan(ts.restartPolicy)}   Grace period: #{color.cyan(ts.terminationGracePeriodSeconds)}s  
          
            Labels:      #{record.metadata.labels.to_h.reject{|k,_| ["pod-template-hash", :version].include?(k)}.map{|k,v| "#{k}=#{color.cyan(v)}"}.join("\n             ")}
            Annotated:   #{record.metadata.annotations.to_h.reject{|k,_| [:"kubectl.kubernetes.io/last-applied-configuration"].include?(k)}.map{|k,v| "#{k}=#{color.cyan(v)}"}.join("\n             ")}
  
            containers:
            #{cnt}
        DONE

        out
      end
    end

    class StatefulSet

    end

    class Deployment

    end
  end
end
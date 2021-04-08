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

      def refresh(fetch, _order = :default)
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
        Resource.new(generator, color).render
      end

      def select_next!
        self.next
      end

      def select_previous!
        previous
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

      def render
        # pp record.to_h
        # row 1 - start time, status, ip, controlled-by
        containers = record.spec.template.spec.containers
        cnw = [containers.map { |c| c[:name].length }.max + 2, 8].max

        statuses = record.status

        status = if statuses[:currentNumberScheduled] == statuses[:desiredNumberScheduled] &&
                    statuses[:numberReady] == statuses[:desiredNumberScheduled] &&
                    statuses[:numberAvailable] == statuses[:desiredNumberScheduled]
                   color.bold.green('Ok')
                 elsif statuses[:numberReady] == 0 || statuses[:numberAvailable] == 0
                   color.bold.red('Critical')
                 else
                   color.bold.yellow('Partially Ready')
                 end

        colwidth = 14

        cnt = containers.map do |c|
          name = c[:name]
          r = <<~CONT
            #{'  ' + _lj("#{color.bold(name)}:", cnw)}
            #{_rj('image:', colwidth)} #{c[:image]} (pull: #{color.cyan(c[:imagePullPolicy])})
            #{_rj('ports:', colwidth)} #{c[:ports]&.map { |p| "#{p[:protocol]}:#{p[:containerPort]}" }&.join(', ')}
          CONT
          if c[:volumeMounts]
            r += "#{_rj('mounts:', colwidth)} #{c[:volumeMounts].map do |v|
                                                  "#{v[:name]} -> #{v[:mountPath]}#{v[:readOnly] ? ' [ro]' : color.yellow(' [w+]')}"
                                                end&.join("\n" + _lj(' ',
                                                                     colwidth + 1).to_s)}"
            r += "\n"
          end
          r
        end
        cnt = cnt.join("\n")

        ts = record.spec.template.spec

        w = ["#{record.metadata.namespace}/#{record.metadata.name}".length, ts.schedulerName.length].max + 1
        <<~DONE

          #{_lj("#{record.kind}:", colwidth)} #{_lj("#{record.metadata.namespace}/#{color.white(record.metadata.name)}", w)}   Status: #{status}
          #{_lj('Scheduler:', colwidth)} #{_lj(color.cyan(ts.schedulerName), w)}   Restart: #{color.cyan(ts.restartPolicy)}   Grace period: #{color.cyan(ts.terminationGracePeriodSeconds)}s

          #{_lj('Labels:', colwidth)} #{record.metadata.labels.to_h.reject { |k, _| ['pod-template-hash', :version].include?(k) }.map { |k, v| "#{k}=#{color.cyan(v)}" }.join("\n" + _lj(' ', colwidth + 1))}
          #{_lj('Annotated:', colwidth)} #{record.metadata.annotations.to_h.reject { |k, _| [:"kubectl.kubernetes.io/last-applied-configuration"].include?(k) }.map { |k, v| "#{k}=#{color.cyan(v)}" }.join("\n" + _lj(' ', colwidth + 1))}

          #{color.blue.bold('containers:')}
          #{cnt}
        DONE
      end
    end

    class StatefulSet
    end

    class Deployment
    end
  end
end

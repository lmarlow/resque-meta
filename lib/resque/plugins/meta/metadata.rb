require 'time'

module Resque
  module Plugins
    module Meta
      class Metadata
        attr_reader :job_class, :meta_id, :data, :enqueued_at, :expire_in

        def initialize(data_hash)
          data_hash['enqueued_at'] ||= to_time_format_str(Time.now)
          @data = data_hash
          @meta_id = data_hash['meta_id'].dup
          @enqueued_at = from_time_format_str('enqueued_at')
          @job_class = data_hash['job_class']
          if @job_class.is_a?(String)
            @job_class = Resque.constantize(data_hash['job_class'])
          else
            data_hash['job_class'] = @job_class.to_s
          end
          @expire_in = @job_class.expire_meta_in || 0
        end

        def reload!
          if new_meta = job_class.get_meta(meta_id)
            @data = new_meta.data
          end
          self
        end

        def save
          job_class.store_meta(self)
          self
        end

        def [](key)
          data[key]
        end

        def []=(key, val)
          data[key.to_s] = val
        end

        def start!
          self['started_at'] = to_time_format_str(Time.now)
          save
        end

        def started_at
          from_time_format_str('started_at')
        end

        def finish!
          data['succeeded'] = true unless data.has_key?('succeeded')
          self['finished_at'] = to_time_format_str(Time.now)
          save
        end

        def finished_at
          from_time_format_str('finished_at')
        end

        def expire_at
          if finished? && expire_in > 0
            finished_at.to_i + expire_in
          else
            0
          end
        end

        def enqueued?
          started_at ? false : true
        end

        def working?
          started_at && !finished_at ? true : false
        end

        def started?
          started_at ? true :false
        end

        def finished?
          finished_at ? true : false
        end

        def fail!
          self['succeeded'] = false
          finish!
        end

        def succeeded?
          finished? ? self['succeeded'] : nil
        end

        def failed?
          finished? ? !self['succeeded'] : nil
        end

        def seconds_enqueued
          (started? ? started_at : Time.now.to_i) - enqueued_at.to_i
        end

        def seconds_processing
          if started?
            (finished? ? finished_at : Time.now.to_i) - started_at.to_i
          else
            0
          end
        end

        protected

        def from_time_format_str(key)
          (t = self[key]) && Time.parse(t)
        end

        def to_time_format_str(time)
          time.utc.iso8601(6)
        end
      end
    end
  end
end

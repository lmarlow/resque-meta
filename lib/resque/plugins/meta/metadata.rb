require 'time'

module Resque
  module Plugins
    module Meta
      class Metadata
        attr_reader :job_class, :meta_id, :data, :enqueued_at, :expire_in, :expire_default_in

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
          @expire_default_in = @job_class.expire_meta_default_in || 0
        end

        # Reload the metadata from the store
        def reload!
          if new_meta = job_class.get_meta(meta_id)
            @data = new_meta.data
          end
          self
        end

        # Save the metadata
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
          @started_at = Time.now
          self['started_at'] = to_time_format_str(@started_at)
          save
        end

        def started_at
          @started_at ||= from_time_format_str('started_at')
        end

        def finish!
          data['succeeded'] = true unless data.has_key?('succeeded')
          @finished_at = Time.now
          self['finished_at'] = to_time_format_str(@finished_at)
          save
        end

        def finished_at
          @finished_at ||= from_time_format_str('finished_at')
        end

        def expire_at
          # expiry after finished
          if finished? && expire_in > 0
            finished_at.to_i + expire_in
          # expiry after enqueued
          elsif expire_default_in > 0
            enqueued_at.to_i + expire_default_in
          # default ttl is forever
          else
            0
          end
        end

        def enqueued?
          !started?
        end

        def working?
          started? && !finished?
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
          (started_at || Time.now).to_f - enqueued_at.to_f
        end

        def seconds_processing
          if started?
            (finished_at || Time.now).to_f - started_at.to_f
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

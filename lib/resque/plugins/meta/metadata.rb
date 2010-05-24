module Resque
  module Plugins
    module Meta
      class Metadata
        attr_reader :job_class, :meta_id, :data, :enqueued_at, :expire_in

        def initialize(data_hash)
          data_hash['_enqueued_at'] ||= to_sec_and_usec(Time.now)
          @data = data_hash
          @meta_id = data_hash['_meta_id'].dup
          @enqueued_at = from_sec_and_usec('_enqueued_at')
          @job_class = data_hash['_job_class']
          if @job_class.is_a?(String)
            @job_class = Resque.constantize(data_hash['_job_class'])
          else
            data_hash['_job_class'] = @job_class.to_s
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
          self['_started_at'] = to_sec_and_usec(Time.now)
          save
        end

        def started_at
          from_sec_and_usec('_started_at')
        end

        def finish!
          data['_succeeded'] = true unless data.has_key?('_succeeded')
          self['_finished_at'] = to_sec_and_usec(Time.now)
          save
        end

        def finished_at
          from_sec_and_usec('_finished_at')
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
          self['_succeeded'] = false
          finish!
        end

        def succeeded?
          finished? ? self['_succeeded'] : nil
        end

        def failed?
          finished? ? !self['_succeeded'] : nil
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

        def from_sec_and_usec(key)
          (t = self[key]) && Time.at(*t)
        end

        def to_sec_and_usec(time)
          [time.to_i, time.usec]
        end
      end
    end
  end
end

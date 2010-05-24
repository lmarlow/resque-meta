module Resque
  module Plugins
    module Meta
      class Metadata
        attr_reader :job_class
        attr_reader :meta_id
        attr_reader :data
        attr_reader :enqueued_at

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
        end

        def reload!
          if new_meta = job_class.get_meta(meta_id)
            @data = new_meta.data
          end
          self
        end

        def save
          job_class.store_meta(self)
        end

        def [](key)
          data[key]
        end

        def []=(key, val)
          data[key.to_s] = val
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

require 'resque/plugins/meta/version'

Gem::Specification.new do |s|
  s.name              = "resque-meta"
  s.version           = Resque::Plugins::Meta::Version
  s.date              = Time.now.strftime('%Y-%m-%d')
  s.summary           = "A Resque plugin for storing job metadata."
  s.homepage          = "http://github.com/lmarlow/resque-meta"
  s.email             = "lee.marlow@gmail.com"
  s.authors           = [ "Lee Marlow" ]
  s.has_rdoc          = false

  s.files             = %w( README.md Rakefile LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("test/**/*")

  s.description       = <<desc
A Resque plugin.  If you want to be able to add metadata for a job
to track anything you want, extend it with this module.

For example:

    class MyJob
      extend Resque::Jobs::Meta

      def self.perform(meta_id, *args)
        heavy_lifting
      end
    end

    meta0 = MyJob.enqueue('stuff')
    meta0.enqueued_at # => 'Wed May 19 13:42:41 -0600 2010'
    meta0.meta_id # => '03c9e1a045ad012dd20500264a19273c'
    meta0['foo'] = 'bar' # => 'bar'

    # later
    meta1 = MyJob.get_meta('03c9e1a045ad012dd20500264a19273c')
    meta1.job_class # => MyJob
    meta1.enqueued_at # => 'Wed May 19 13:42:41 -0600 2010'
    meta1['foo'] # => 'bar'
desc

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    s.add_runtime_dependency('resque', [">= 1.8.0"])
  else
    s.add_dependency('resque', [">= 1.8.0"])
  end
end

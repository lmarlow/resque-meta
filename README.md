Resque Meta
===========

A [Resque][rq] plugin. Requires Resque 1.8.

If you want to be able to add metadata for a job
to track anything you want, extend it with this module.

For example:

    require 'resque-meta'

    class MyJob
      extend Resque::Plugins::Meta

      def self.perform(meta_id, *args)
        heavy_lifting
      end
    end

    meta0 = MyJob.enqueue('stuff')
    meta0.enqueued_at # => 'Wed May 19 13:42:41 -0600 2010'
    meta0.meta_id # => '03c9e1a045ad012dd20500264a19273c'
    meta0['foo'] = 'bar' # => 'bar'
    meta0.save

    # later
    meta1 = MyJob.get_meta('03c9e1a045ad012dd20500264a19273c')
    meta1.job_class # => MyJob
    meta1.enqueued_at # => 'Wed May 19 13:42:41 -0600 2010'
    meta1['foo'] # => 'bar'

[rq]: http://github.com/defunkt/resque

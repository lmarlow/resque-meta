require File.dirname(__FILE__) + '/test_helper'
require 'resque-meta'

class MetaJob
  extend Resque::Plugins::Meta
  @queue = :test

  def self.expire_meta_in
    1
  end

  def self.perform(meta_id, key, val)
    meta = get_meta(meta_id)
    meta[key] = val
    meta.save
  end
end

class AnotherJob
  extend Resque::Plugins::Meta
  @queue = :test

  def self.perform(meta_id)
  end
end

class SlowJob
  extend Resque::Plugins::Meta
  @queue = :test

  def self.expire_meta_in
    1
  end

  def self.perform(meta_id, key, val)
    meta = get_meta(meta_id)
    meta[key] = val
    meta.save
    sleep 1
  end
end

class FailingJob
  extend Resque::Plugins::Meta
  @queue = :test

  def self.perform(*args)
    raise 'boom'
  end
end

class TransientJob
  extend Resque::Plugins::Meta
  @queue = :test

  def self.perform(meta_id)
  end

  def self.before_finish_expire_in
    1
  end
end

class MetaTest < Test::Unit::TestCase
  def setup
    Resque.redis.flushall
  end

  def test_meta_version
    assert_equal '2.0.1', Resque::Plugins::Meta::Version
  end

  def test_lint
    assert_nothing_raised do
      Resque::Plugin.lint(Resque::Plugins::Meta)
    end
  end

  def test_resque_version
    major, minor, patch = Resque::Version.split('.')
    assert_equal 1, major.to_i
    assert minor.to_i >= 8
  end

  def test_enqueued_metadata
    now = Time.now
    meta = MetaJob.enqueue('foo', 'bar')
    assert_not_nil meta
    assert_not_nil meta.meta_id
    assert meta.enqueued_at.to_f > now.to_f, "#{meta.enqueued_at} should be after #{now}"
    assert meta.seconds_enqueued > 0.0, "seconds_enqueued should be greater than zero"
    assert meta.enqueued?
    assert !meta.started?
    assert_equal 0, meta.seconds_processing
    assert !meta.finished?
    assert_nil meta['foo']
    assert_equal Resque::Plugins::Meta::Metadata, meta.class
    assert_equal MetaJob, meta.job_class
  end

  def test_processed_job
    meta = MetaJob.enqueue('foo', 'bar')
    assert_nil meta['foo']
    worker = Resque::Worker.new(:test)
    worker.work(0)

    meta = MetaJob.get_meta(meta.meta_id)
    assert_equal MetaJob, meta.job_class
    assert meta.started?
    assert meta.finished?, 'Job should be finished'
    assert meta.succeeded?, 'Job should have succeeded'
    assert !meta.enqueued?
    assert meta.seconds_enqueued > 0.0, "seconds_enqueued should be greater than zero"
    assert meta.seconds_processing > 0.0, "seconds_processing should be greater than zero"
    assert_equal 'bar', meta['foo'], "'foo' not found in #{meta.inspect}"
  end

  def test_wrong_id_for_class
    meta = MetaJob.enqueue('foo', 'bar')

    assert_nil AnotherJob.get_meta(meta.meta_id)
    assert_not_nil Resque::Plugins::Meta.get_meta(meta.meta_id)
  end

  def test_expired_metadata
    meta = MetaJob.enqueue('foo', 'bar')
    worker = Resque::Worker.new(:test)
    worker.work(0)

    sleep 2
    meta = MetaJob.get_meta(meta.meta_id)
    assert_nil meta
  end

  def test_expired_metadata_before_finished
    meta = TransientJob.enqueue()
    worker = Resque::Worker.new(:test)
    assert meta = TransientJob.get_meta(meta.meta_id)

    sleep 2
    meta = TransientJob.get_meta(meta.meta_id)
    assert_equal nil, meta
  end

  def test_slow_job
    meta = SlowJob.enqueue('foo', 'bar')
    worker = Resque::Worker.new(:test)
    thread = Thread.new { worker.work(0) }

    sleep 0.1
    meta = SlowJob.get_meta(meta.meta_id)
    assert !meta.enqueued?
    assert meta.started?
    assert meta.working?
    assert !meta.finished?

    thread.join # job should be done
    meta.reload!
    assert !meta.enqueued?
    assert meta.started?
    assert !meta.working?
    assert meta.finished?
    assert meta.succeeded?
    assert !meta.failed?

    sleep 2
    assert_nil Resque::Plugins::Meta.get_meta(meta.meta_id)
  end

  def test_failing_job
    meta = FailingJob.enqueue()
    assert_nil meta.failed?
    worker = Resque::Worker.new(:test)
    worker.work(0)

    meta.reload!
    assert meta.finished?
    assert meta.failed?
    assert !meta.succeeded?
  end

  def test_saving_additional_metadata
    meta = MetaJob.enqueue('stuff')
    meta['foo'] = 'bar'
    meta.save

    # later
    meta = MetaJob.get_meta(meta.meta_id)
    assert_equal 'bar', meta['foo']
  end
end

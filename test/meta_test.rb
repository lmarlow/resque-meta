require 'test/unit'
require 'rubygems'
require 'resque'
require 'resque/plugins/meta'

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

class MetaTest < Test::Unit::TestCase
  def setup
    Resque.redis.flushall
  end
  
  def test_lint
    assert_nothing_raised do
      Resque::Plugin.lint(Resque::Plugins::Meta)
    end
  end

  def test_version
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
    assert_equal 'bar', meta['foo'], "'foo' not found in #{meta.inspect}"
  end

  def test_wrong_id_for_class
    meta = MetaJob.enqueue('foo', 'bar')

    assert_nil AnotherJob.get_meta(meta.meta_id)
  end

  def test_expired_metadata
    meta = MetaJob.enqueue('foo', 'bar')
    worker = Resque::Worker.new(:test)
    worker.work(0)

    sleep 2
    meta = MetaJob.get_meta(meta.meta_id)
    assert_nil meta
  end
end

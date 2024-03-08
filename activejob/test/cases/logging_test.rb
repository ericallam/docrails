# frozen_string_literal: true

require "helper"
require "active_support/log_subscriber/test_helper"
require "active_support/core_ext/numeric/time"
require "jobs/hello_job"
require "jobs/logging_job"
require "jobs/overridden_logging_job"
require "jobs/nested_job"
require "jobs/rescue_job"
require "models/person"

class LoggingTest < ActiveSupport::TestCase
  include ActiveSupport::LogSubscriber::TestHelper
  include ActiveSupport::Logger::Severity

  class TestLogger < ActiveSupport::Logger
    def initialize
      @file = StringIO.new
      super(@file)
    end

    def messages
      @file.rewind
      @file.read
    end
  end

  def setup
    super
    JobBuffer.clear
    @old_logger = ActiveJob::Base.logger
    @logger = ActiveSupport::TaggedLogging.new(TestLogger.new)
    set_logger @logger
    ActiveJob::Logging::LogSubscriber.attach_to :active_job
  end

  def teardown
    super
    ActiveJob::Logging::LogSubscriber.log_subscribers.pop
    set_logger @old_logger
  end

  def set_logger(logger)
    ActiveJob::Base.logger = logger
  end

  def test_uses_active_job_as_tag
    HelloJob.perform_later "Cristian"
    assert_match(/\[ActiveJob\]/, @logger.messages)
  end

  def test_uses_job_name_as_tag
    LoggingJob.perform_later "Dummy"
    assert_match(/\[LoggingJob\]/, @logger.messages)
  end

  def test_uses_job_id_as_tag
    LoggingJob.perform_later "Dummy"
    assert_match(/\[LOGGING-JOB-ID\]/, @logger.messages)
  end

  def test_logs_correct_queue_name
    original_queue_name = LoggingJob.queue_name
    LoggingJob.queue_as :php_jobs
    LoggingJob.perform_later("Dummy")
    assert_match(/to .*?\(php_jobs\).*/, @logger.messages)
  ensure
    LoggingJob.queue_name = original_queue_name
  end

  def test_globalid_parameter_logging
    person = Person.new(123)
    LoggingJob.perform_later person
    assert_match(%r{Enqueued.*gid://aj/Person/123}, @logger.messages)
    assert_match(%r{Dummy, here is it: #<Person:.*>}, @logger.messages)
    assert_match(%r{Performing.*gid://aj/Person/123}, @logger.messages)
  end

  def test_globalid_nested_parameter_logging
    person = Person.new(123)
    LoggingJob.perform_later(person: person)
    assert_match(%r{Enqueued.*gid://aj/Person/123}, @logger.messages)
    assert_match(%r{Dummy, here is it: .*#<Person:.*>}, @logger.messages)
    assert_match(%r{Performing.*gid://aj/Person/123}, @logger.messages)
  end

  def test_enqueue_job_logging
    HelloJob.perform_later "Cristian"
    assert_match(/Enqueued HelloJob \(Job ID: .*?\) to .*?:.*Cristian/, @logger.messages)
  end

  def test_perform_job_logging
    LoggingJob.perform_later "Dummy"
    assert_match(/Performing LoggingJob \(Job ID: .*?\) from .*? with arguments:.*Dummy/, @logger.messages)
    assert_match(/Dummy, here is it: Dummy/, @logger.messages)
    assert_match(/Performed LoggingJob \(Job ID: .*?\) from .*? in .*ms/, @logger.messages)
  end

  def test_perform_nested_jobs_logging
    NestedJob.perform_later
    assert_match(/\[LoggingJob\] \[.*?\]/, @logger.messages)
    assert_match(/\[ActiveJob\] Enqueued NestedJob \(Job ID: .*\) to/, @logger.messages)
    assert_match(/\[ActiveJob\] \[NestedJob\] \[NESTED-JOB-ID\] Performing NestedJob \(Job ID: .*?\) from/, @logger.messages)
    assert_match(/\[ActiveJob\] \[NestedJob\] \[NESTED-JOB-ID\] Enqueued LoggingJob \(Job ID: .*?\) to .* with arguments: "NestedJob"/, @logger.messages)
    assert_match(/\[ActiveJob\].*\[LoggingJob\] \[LOGGING-JOB-ID\] Performing LoggingJob \(Job ID: .*?\) from .* with arguments: "NestedJob"/, @logger.messages)
    assert_match(/\[ActiveJob\].*\[LoggingJob\] \[LOGGING-JOB-ID\] Dummy, here is it: NestedJob/, @logger.messages)
    assert_match(/\[ActiveJob\].*\[LoggingJob\] \[LOGGING-JOB-ID\] Performed LoggingJob \(Job ID: .*?\) from .* in/, @logger.messages)
    assert_match(/\[ActiveJob\] \[NestedJob\] \[NESTED-JOB-ID\] Performed NestedJob \(Job ID: .*?\) from .* in/, @logger.messages)
  end

  def test_enqueue_at_job_logging
    HelloJob.set(wait_until: 24.hours.from_now).perform_later "Cristian"
    assert_match(/Enqueued HelloJob \(Job ID: .*\) to .*? at.*Cristian/, @logger.messages)
  rescue NotImplementedError
    skip
  end

  def test_enqueue_in_job_logging
    HelloJob.set(wait: 2.seconds).perform_later "Cristian"
    assert_match(/Enqueued HelloJob \(Job ID: .*\) to .*? at.*Cristian/, @logger.messages)
  rescue NotImplementedError
    skip
  end

  def test_for_tagged_logger_support_is_consistent
    set_logger ::Logger.new(nil)
    OverriddenLoggingJob.perform_later "Dummy"
  end

  def test_job_error_logging
    RescueJob.perform_later "other"
  rescue RescueJob::OtherError
    assert_match(/Performing RescueJob \(Job ID: .*?\) from .*? with arguments:.*other/, @logger.messages)
    assert_match(/Error performing RescueJob \(Job ID: .*?\) from .*? in .*ms: RescueJob::OtherError \(Bad hair\):\n.*\brescue_job\.rb:\d+:in `perform'/, @logger.messages)
  end
end

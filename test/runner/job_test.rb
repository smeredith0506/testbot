require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/shared/testbot.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '../../lib/runner/job.rb'))
require 'test/unit'
require 'shoulda'
require 'flexmock/test_unit'

module Testbot::Runner

  class JobTest < Test::Unit::TestCase

    def expect_put_with(id, result_text, status, time = 0)
      expected_result = "\n#{`hostname`.chomp}:#{Dir.pwd}\n"
      expected_result += result_text
      flexmock(Server).should_receive(:put).once.with("/jobs/#{id}", :body =>
                                                      { :result => expected_result, :status => status, :time => time })
    end

    def expect_put
      flexmock(Server).should_receive(:put).once
    end

    def expect_put_to_timeout
      flexmock(Server).should_receive(:put).and_raise(Timeout::Error)
    end

    def stub_duration(seconds)
      time ||= Time.now
      flexmock(Time).should_receive(:now).and_return(time, time + seconds)
    end

    should "be able to run a successful job" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)
      stub_duration(0)

      expect_put_with(10, "result text", "successful")
      flexmock(job).should_receive(:run_and_return_result).once.
        with("export RAILS_ENV=test; export TEST_ENV_NUMBER=; cd project; export RSPEC_COLOR=true; ruby -S bundle exec rspec spec/foo_spec.rb spec/bar_spec.rb").
        and_return('result text')
      flexmock(RubyEnv).should_receive(:bundler?).returns(true)
      flexmock(RubyEnv).should_receive(:rvm?).returns(false)
      job.run(0)
    end

    should "not raise an error when posting results time out" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)

      # We're using send here because triggering post_results though the rest of the
      # code requires very complex setup. The code need to be refactored to be more testable.
      expect_put
      job.send(:post_results, "result text")
      expect_put_to_timeout
      job.send(:post_results, "result text")
    end

    should "not be successful when the job fails" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)
      stub_duration(0)

      expect_put_with(10, "result text", "failed")
      flexmock(job).should_receive(:run_and_return_result).and_return('result text')
      flexmock(job).should_receive(:success?).and_return(false)
      job.run(0)
    end

    should "set an instance number when the instance is not 0" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)
      stub_duration(0)

      expect_put_with(10, "result text", "successful")
      flexmock(job).should_receive(:run_and_return_result).
        with(/TEST_ENV_NUMBER=2/).
        and_return('result text')
      flexmock(RubyEnv).should_receive(:rvm?).returns(false)
      job.run(1)
    end

    should "return test runtime in milliseconds" do
      job = Job.new(Runner.new({}), 10, "00:00", "project", "/tmp/testbot/user", "spec", "ruby", "spec/foo_spec.rb spec/bar_spec.rb")
      flexmock(job).should_receive(:puts)

      stub_duration(10.55)
      expect_put_with(10, "result text", "successful", 1055)
      flexmock(job).should_receive(:run_and_return_result).and_return('result text')
      flexmock(RubyEnv).should_receive(:rvm?).returns(false)
      job.run(0)
    end

  end

end

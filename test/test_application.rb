require 'test/unit'
require 'test/capture_stdout'
require 'lib/timesheet'

class TestApplication < Test::Unit::TestCase
  include CaptureStdout

  def setup
    @app = Timesheet::Application.new
    def @app.exit(*args)
      throw :system_exit
    end
  end

  def test_display_usage_when_no_command
    set_argv []
    assert_match(/usage/i, capture_system_error)
  end

  def test_display_usage_when_invalid_command
    set_argv "foo"
    assert_match(/unknown/i, capture_system_error)
  end

  def set_argv(argv)
    ARGV.clear
    argv.each { |e| ARGV << e }
  end

  def capture_system_error(&block)
    capture_stderr { 
      catch(:system_exit) { @app.run }
    }
  end

end

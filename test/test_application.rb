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

  def test_no_command
    ARGV.clear
    err = capture_stderr { 
      catch(:system_exit) { @app.run }
    }
    assert_match(/usage/i, err)
  end 

end

require 'test/unit'
require 'test/capture_stdout'
require 'lib/timesheet'
require 'mocha'

class TestApplication < Test::Unit::TestCase
  include CaptureStdout

  def setup
    @app = Timesheet::Application.new
  end

  def test_get_command 
    [["foo"], ["foo", "bar", "baz"]].each do |args|
      c, a = @app.get_command(args)
      assert_equal args.shift, c
      assert_equal args, a
    end
  end

  def test_get_command_with_no_command
    assert_raise(ArgumentError) do
      @app.get_command([])
    end 
  end

  def test_validate_command
    assert_nothing_raised do
      @app.validate_command("start")
    end 
  end

  def test_validate_command_invalid
    assert_raise(ArgumentError) do
      @app.validate_command("invalid")
    end
  end

  def test_run
    Timesheet::Timesheet.any_instance.expects(:log)
    ARGV << "log"
    @app.run
  end
 
  def test_run_error_msg_when_exception_raised
    def @app.exit(*args)
      throw :system_exit
    end
   
    def @app.get_command(args)
      raise Exception, "foo"
    end
    
    err = capture_stderr { 
      catch(:system_exit) { 
        @app.run 
      } 
    }
    assert_match("timesheet: foo", err)
  end

end

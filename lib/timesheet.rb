#
# Copyright (c) 2008 Dustin Barker
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#

require 'rubygems'
require 'activerecord'
require 'sqlite3'

module Timesheet
  
  class << self
  
    def application
      @application ||= Application.new
    end

  end
    
  class Application

    def run
      begin 
        command = ARGV[0]
        raise ArgumentError, "type 'timesheet help' for usage" unless command 
        raise ArgumentError, "unknown command: #{command}" unless Timesheet.public_instance_methods.include?(command)

        dbfile = "#{ENV['HOME']}/timesheet"
        unless File.exist?(dbfile)
          `sqlite3 #{dbfile} < schema.sql`
        end

        ActiveRecord::Base.establish_connection(
          :adapter  => "sqlite3",
          :dbfile => dbfile
        )
     
        ARGV.shift 
        Timesheet.new.send(command.to_sym, *ARGV)
      rescue Exception => ex
        $stderr.puts "timesheet: #{ex.message}"
        exit(1)
      end
    end

  end

  class Timesheet

    def start(name = nil)
      raise ArgumentError, "must specify task" unless name
      task = Task.find_or_create_by_name(name)

      active = Entry.active
      if active 
        raise ArgumentError, "task #{task.name} already started." if active.task == task 
        stop0(active)
      end

      puts "starting task #{task.name}"
      Entry.create(:task => task, :started_at => Time.now)
    end

    def stop
      active = Entry.active
      raise ArgumentError, "no task has been started" unless active
      stop0(active)
    end

    def tasks
      Task.find(:all, :order => 'name').each do |t|
        puts t.name
      end
    end

    def status
      active = Entry.active
      if active
        h, m, s, f = Date.day_fraction_to_time(active.duration)
        puts "task: #{active.task.name} duration: #{h} hours, #{m} minutes, #{s} seconds"
      else
        puts "no task has been started"
      end 
    end

  private

    def stop0(entry)
      puts "stopping task #{entry.task.name}"
      entry.stop!
    end

  end

  class Task < ActiveRecord::Base
    has_many :entries
  end

  class Entry < ActiveRecord::Base
    belongs_to :task

    class << self
      def active
        Entry.find(:first, :conditions => {:stopped_at => nil})
      end
    end

    def stop!
      Entry.update(self, :stopped_at => Time.now)
    end

    def duration
      duration = (stopped_at || Time.now.to_i) - started_at
    end

  end

end

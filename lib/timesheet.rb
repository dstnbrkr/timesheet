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
require 'optparse'
require 'sqlite3'

module Timesheet
  
  class << self
  
    def application
      @application ||= Application.new
    end

  end
    
  class Application

    COMMANDS = ["start"]

    def run
      command = ARGV[0]
      unless Timesheet.public_instance_methods.include?(command)
        puts "timesheet: Unknown command: #{command}"
        exit
      end

      dbfile = "#{ENV['HOME']}/timesheet"
      unless File.exist?(dbfile)
        `sqlite3 #{dbfile} < schema.sql`
      end

      ActiveRecord::Base.establish_connection(
        :adapter  => "sqlite3",
        :dbfile => dbfile
      )
      
      Timesheet.new.send(command.to_sym)
    end

  end

  class Timesheet

    def start
      require_task

      # FIXME: cannot start task if already started
      task = Task.find_or_create_by_name(ARGV[1])
      Entry.create(:task => task, :started_at => Time.now)
    end

    def stop
      require_task

      # FIXME: cannot stop task if not started
      task = Task.find_by_name(ARGV[1])
      entry = Entry.find(:first, :conditions => {:task_id => task.id, :stopped_at => nil})
      Entry.update(entry, :stopped_at => Time.now)
    end

  private

    def require_task
      unless ARGV[1]
        puts "timesheet: must specify task"
        exit
      end
    end
  
  end

  class Task < ActiveRecord::Base
    has_many :entries
  end

  class Entry < ActiveRecord::Base
    belongs_to :task
  end

end

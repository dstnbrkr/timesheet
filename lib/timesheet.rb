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

dbfile = "#{ENV['HOME']}/timesheet"
unless File.exist?(dbfile)
  `sqlite3 #{dbfile} < schema.sql`
end
ActiveRecord::Base.establish_connection(
  :adapter  => "sqlite3",
  :dbfile => dbfile
)

module Timesheet
  
  class << self
    def application
      @application ||= Application.new
    end
  end
    
  class Application

    def run
      begin
        command, args = get_command(ARGV)
        validate_command(command) 
        Timesheet.new.send(command, *args)
      rescue Exception => ex
        $stderr.puts "timesheet: #{ex.message}"
        exit(1)
      end
    end

    def get_command(args)
      raise ArgumentError, "type 'timesheet help' for usage" unless args[0]
      return args[0], args[1, args.size - 1]
    end

    def validate_command(command)
      unless Timesheet.public_instance_methods.include?(command)
        raise ArgumentError, "unknown command: #{command}"
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

    def status
      active = Entry.active
      if active
        h, m = Entry.duration_parts(active.duration)
        puts "task: #{active.task.name} duration: #{h} hours, #{m} minutes"
      else
        puts "no task has been started"
      end 
    end

    def log
      w1 = Task.find(:all).collect { |t| t.name.length }.max
      w2 = Entry.find(:all).collect { |e| h, m = e.duration; h.to_s.length }.max
      
      puts
      days = totals_by_task_by_day
      days.keys.sort.each do |day|
        puts days[day]
        days[day].each do |task, duration|
          h, m = Entry.duration_parts(duration)
          printf "%-#{w1}s  %#{w2}i:%02i\n", task.name, h, m
        end 
        puts
      end 
    end

  private

    def stop0(entry)
      puts "stopping task #{entry.task.name}"
      entry.stop!
    end

    def timestamp_to_date(timestamp)
      Date.parse(Time.at(timestamp).strftime('%Y/%m/%d'))
    end

    def totals_by_task_by_day
      days = {}
      Entry.find(:all).each do |e|
        day = timestamp_to_date(e.started_at)
        days[day] = {} unless days[day]
        days[day][e.task] = 0 unless days[day][e.task]
        days[day][e.task] += e.duration
      end
      days
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

      def duration_parts(duration)
        d = duration
        h, d = d.divmod(1.hour)
        m, d = d.divmod(1.minute)
        return h, m
      end 
    end

    def stop!
      Entry.update(self, :stopped_at => Time.now)
    end

    def duration
      (stopped_at || Time.now.to_i) - started_at
    end

  end

end

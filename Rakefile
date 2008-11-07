# Rakefile for timesheet

require 'rubygems'
require 'rake/testtask'

task :default => :test_units

Rake::TestTask.new(:test_units) do |t|
  t.test_files = FileList['test/test*.rb']
  t.warning = true
  t.verbose = false
end






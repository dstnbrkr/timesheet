spec = Gem::Specification.new do |s| 
  s.name = "timesheet"
  s.version = "0.0.1"
  s.author = "Dustin Barker"
  s.email = "dustin.barker@gmail.com"
  s.homepage = "http://collectiv.org"
  s.platform = Gem::Platform::RUBY
  s.summary = "command line based time tracking utility"
  s.executables = ["timesheet"]
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  #s.has_rdoc = true
  #s.extra_rdoc_files = ["README"]
  s.add_dependency("activerecord", ">= 2.1.0") 
  s.add_dependency("sqlite3-ruby", ">= 1.2.1") 
end

Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end 

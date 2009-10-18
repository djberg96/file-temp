require 'rake'
require 'rake/testtask'
require 'rbconfig'

desc 'Install the file-temp library (non-gem)'
task :install do
   dir = File.join(CONFIG['sitelibdir'], 'file')
   Dir.mkdir(dir) unless File.exists?(dir)
   file = 'lib/file/temp.rb'
   FileUtils.cp_r(file, dir, :verbose => true)
end

desc 'Build the gem'
task :gem do
   spec = eval(IO.read('file-temp.gemspec'))
   Gem::Builder.new(spec).buildend

desc 'Install the file-temp library as a gem'
task :install_gem => [:gem] do
   file = Dir["*.gem"].first
   sh "gem install #{file}"
end

Rake::TestTask.new do |t|
   t.verbose = true
   t.warning = true
end

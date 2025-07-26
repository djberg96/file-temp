require 'rake'
require 'rake/clean'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

CLEAN.include('**/*.tar', '**/*.zip', '**/*.gz', '**/*.bz2')
CLEAN.include('**/*.rbc', '**/*.gem', '**/*.tmp', '**/*.lock')

namespace 'gem' do
  desc 'Create the file-temp gem'
  task :create => [:clean] do
    require 'rubygems/package'
    spec = Gem::Specification.load('file-temp.gemspec')
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec)
  end

  desc 'Install the file-temp gem'
  task :install => [:create] do
     file = Dir["*.gem"].first
     sh "gem install -l #{file}"
  end
end

RuboCop::RakeTask.new

desc 'Run the test suite for the file-temp library'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = false
  t.rspec_opts = '-f documentation'
end

# Clean up afterwards
Rake::Task[:spec].enhance do
  Rake::Task[:clean].invoke
end

task :default => :spec

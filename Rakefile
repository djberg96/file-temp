require 'rake'
require 'rake/clean'
require 'rake/testtask'

CLEAN.include('**/*.tar', '**/*.zip', '**/*.gz', '**/*.bz2')
CLEAN.include('**/*.rbc', '**/*.gem', '**/*.tmp')

namespace 'gem' do
  desc 'Create the file-temp gem'
  task :create => [:clean] do
    require 'rubygems/package'
    spec = eval(IO.read('file-temp.gemspec'))
    spec.signing_key = File.join(Dir.home, '.ssh', 'gem-private_key.pem')
    Gem::Package.build(spec, true)
  end

  desc 'Install the file-temp gem'
  task :install => [:create] do
     file = Dir["*.gem"].first
     sh "gem install -l #{file}"
  end
end

# Export the contents of the library to an archive. Note that this requires
# presence of the .gitattributes file in order to prevent the .git contents
# from being included.
#
# It also appears that I must add a trailing slash to the prefix manually.
# As of git 1.6.4.3 it does not automaticaly add it, despite what the docs
# say.
#
namespace 'export' do
  spec = eval(IO.read('file-temp.gemspec'))
  file = 'file-temp-' + spec.version.to_s
  pref = file + '/' # Git does not add the trailing slash, despite what the docs say.

  desc 'Export to a .tar.gz file'
  task :gzip => [:clean] do
    file += '.tar'
    sh "git archive --prefix #{pref} --output #{file} master"
    sh "gzip #{file}"
  end

  desc 'Export to a .tar.bz2 file'
  task :bzip2 => [:clean] do
    file += '.tar'
    sh "git archive --prefix #{pref} --output #{file} master"
    sh "bzip2 -f #{file}"
  end

  desc 'Export to a .zip file'
  task :zip => [:clean] do
    file += '.zip'
    sh "git archive --prefix #{pref} --output #{file} --format zip master"
  end
end

Rake::TestTask.new do |t|
  t.verbose = true
  t.warning = true
end

task :default => :test

require 'rubygems'

Gem::Specification.new do |gem|
   gem.name      = 'file-temp'
   gem.version   = '1.1.1'
   gem.author    = 'Daniel J. Berger'
   gem.email     = 'djberg96@gmail.com'
   gem.homepage  = 'http://www.rubyforge.org/projects/shards'
   gem.summary   = 'An alternative way to generate temp files'
   gem.test_file = 'test/test_file_temp.rb'
   gem.has_rdoc  = true
   gem.files     = Dir['**/*'].delete_if{ |item| item.include?('CVS') }

   gem.extra_rdoc_files = ['CHANGES', 'README', 'MANIFEST']
   gem.rubyforge_project = 'shards'
   gem.required_ruby_version = '>= 1.8.6'

   gem.add_dependency('ffi', '>= 0.5.0')
   gem.add_development_dependency('test-unit', '>= 2.0.3')

   gem.description = <<-EOF
      The file-temp library provides an alternative approach to generating
      temporary files. Features included improved security, a superior
      interface, and better support for MS Windows.
   EOF
end

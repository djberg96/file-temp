require 'rubygems'

Gem::Specification.new do |spec|
  spec.name      = 'file-temp'
  spec.version   = '1.1.3'
  spec.author    = 'Daniel J. Berger'
  spec.email     = 'djberg96@gmail.com'
  spec.homepage  = 'http://www.rubyforge.org/projects/shards'
  spec.summary   = 'An alternative way to generate temp files'
  spec.test_file = 'test/test_file_temp.rb'
  spec.has_rdoc  = true
  spec.files     = Dir['**/*'].delete_if{ |item| item.include?('git') }

  spec.extra_rdoc_files = ['CHANGES', 'README', 'MANIFEST']
  spec.rubyforge_project = 'shards'
  spec.required_ruby_version = '>= 1.8.6'

  spec.add_dependency('ffi', '>= 0.5.0')
  spec.add_development_dependency('test-unit', '>= 2.0.3')

  spec.description = <<-EOF
    The file-temp library provides an alternative approach to generating
    temporary files. Features included improved security, a superior
    interface, and better support for MS Windows.
  EOF
end

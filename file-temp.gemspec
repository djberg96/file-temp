require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'file-temp'
  spec.version    = '1.3.0'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Artistic 2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/file-temp'
  spec.summary    = 'An alternative way to generate temp files'
  spec.test_file  = 'test/test_file_temp.rb'
  spec.files      = Dir['**/*'].delete_if{ |item| item.include?('git') }
  spec.cert_chain = Dir['certs/*']

  spec.extra_rdoc_files = ['CHANGES', 'README', 'MANIFEST']

  spec.add_dependency('ffi', '>= 1.0.0')
  spec.add_development_dependency('test-unit')
  spec.add_development_dependency('rake')

  spec.description = <<-EOF
    The file-temp library provides an alternative approach to generating
    temporary files. Features included improved security, a superior
    interface, and better support for MS Windows.
  EOF
end

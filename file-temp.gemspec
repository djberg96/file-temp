require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'file-temp'
  spec.version    = '1.7.1'
  spec.author     = 'Daniel J. Berger'
  spec.license    = 'Apache-2.0'
  spec.email      = 'djberg96@gmail.com'
  spec.homepage   = 'http://github.com/djberg96/file-temp'
  spec.summary    = 'An alternative way to generate temp files'
  spec.test_file  = 'spec/file_temp_spec.rb'
  spec.files      = Dir['**/*'].delete_if{ |item| item.include?('git') }
  spec.cert_chain = Dir['certs/*']

  spec.add_dependency('ffi', '~> 1.1')
  spec.add_development_dependency('rspec', '~> 3.9')
  spec.add_development_dependency('rake')

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/djberg96/file-temp',
    'bug_tracker_uri'   => 'https://github.com/djberg96/file-temp/issues',
    'changelog_uri'     => 'https://github.com/djberg96/file-temp/blob/main/CHANGES.md',
    'documentation_uri' => 'https://github.com/djberg96/file-temp/wiki',
    'source_code_uri'   => 'https://github.com/djberg96/file-temp',
    'wiki_uri'          => 'https://github.com/djberg96/file-temp/wiki'
  }

  spec.description = <<-EOF
    The file-temp library provides an alternative approach to generating
    temporary files. Features included improved security, a superior
    interface, and better support for MS Windows.
  EOF
end

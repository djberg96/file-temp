# frozen_string_literal: true

######################################################################
# file_temp_spec.rb
#
# Test suite for the file-temp library. These tests should be run
# via the 'rake spec' task.
######################################################################
require 'rspec'
require 'file/temp'

RSpec.describe File::Temp do
  let(:windows) { File::ALT_SEPARATOR }
  let(:osx) { RbConfig::CONFIG['host_os'] =~ /darwin/i }

  before do
    @dir = File::Temp::TMPDIR
    @template = 'file-temp-test-XXXXX'
    @fh = nil

    # Because Dir[] doesn't work right with backslashes
    @dir = @dir.tr('\\', '/') if windows
  end

  context 'constants' do
    example 'library version is set to expected value' do
      expect(File::Temp::VERSION).to eq('1.7.1')
      expect(File::Temp::VERSION).to be_frozen
    end

    example 'TMPDIR constant is defined' do
      expect(File::Temp::TMPDIR).to be_kind_of(String)
      expect(File::Temp::TMPDIR.size).to be > 0
    end
  end

  context 'threads' do
    example 'library works as expected with multiple threads' do
      threads = []
      expect{ 100.times{ threads << Thread.new{ described_class.new }}}.not_to raise_error
      expect{ threads.each(&:join) }.not_to raise_error
    end
  end

  context 'constructor' do
    example 'constructor works as expected with default auto delete option' do
      expect{
        @fh = described_class.new
        @fh.print 'hello'
        @fh.close
      }.not_to raise_error
    end

    example 'constructor works as expected with false auto delete option' do
      expect{
        @fh = described_class.new(:delete => false)
        @fh.print 'hello'
        @fh.close
      }.not_to raise_error
    end

    example 'constructor accepts and uses an optional template as expected' do
      expect{ described_class.new(:delete => false, :template => 'temp_foo_XXXXXX').close }.not_to raise_error
      expect(Dir["#{@dir}/temp_foo*"].length).to be >= 1
    end

    example 'constructor with false auto delete and block works as expected' do
      expect{
        described_class.open(:delete => false, :template => 'temp_foo_XXXXXX'){ |fh| fh.puts 'hello' }
      }.not_to raise_error
      expect(Dir["#{@dir}/temp_foo*"].length).to be >= 1
    end

    example 'other arguments are treated as file option arguments' do
      expect{
        @fh = described_class.new(
          :delete    => true,
          :template  => 'temp_bar_XXXXX',
          :directory => Dir.pwd,
          :mode      => 'xb'
        )
      }.to raise_error(ArgumentError, /invalid.*?(access)?.*?mode/) # Truffleruby missing the word 'access'
    end
  end

  context 'template' do
    example 'template argument must be a string' do
      expect{ @fh = described_class.new(:delete => false, :template => 1) }.to raise_error(TypeError)
    end

    example 'an error is raised if a custom template is invalid' do
      skip 'skipped on OSX' if osx
      expect{ described_class.new(:delete => false, :template => 'xx') }.to raise_error(Errno::EINVAL)
    end
  end

  context 'temp_name' do
    example 'temp_name basic functionality' do
      expect(described_class).to respond_to(:temp_name)
      expect{ described_class.temp_name }.not_to raise_error
      expect(described_class.temp_name).to be_kind_of(String)
    end

    example 'temp_name returns expected value' do
      if windows
        expect(File.extname(described_class.temp_name)).to match(/^.*?\d*?tmp/)
      else
        expect(File.extname(described_class.temp_name)).to eq('.tmp')
      end
    end
  end

  context 'path' do
    example 'temp path basic functionality' do
      @fh = described_class.new
      expect(@fh).to respond_to(:path)
    end

    example 'temp path is nil if delete option is true' do
      @fh = described_class.new
      expect(@fh.path).to be_nil
    end

    example 'temp path is not nil if delete option is false' do
      @fh = described_class.new(delete: false)
      expect(@fh.path).not_to be_nil
    end
  end

  context 'ffi' do
    before do
      @methods = described_class.methods(false).map(&:to_s)
    end

    example 'ffi unix functions are private', :unix do
      expect(@methods).not_to include('_fileno')
      expect(@methods).not_to include('mkstemp')
      expect(@methods).not_to include('_umask')
      expect(@methods).not_to include('fclose')
      expect(@methods).not_to include('strerror')
      expect(@methods).not_to include('tmpnam')
    end

    example 'ffi windows functions are private', :windows do
      expect(@methods).not_to include('CloseHandle')
      expect(@methods).not_to include('CreateFileA')
      expect(@methods).not_to include('DeleteFileA')
      expect(@methods).not_to include('GetTempPathA')
      expect(@methods).not_to include('GetTempFileNameA')
    end
  end

  after do
    @dir = nil
    @template = nil
    @fh.close if @fh && !@fh.closed?
    @fh = nil

    Dir['temp_*'].each{ |f| File.delete(f) }
    Dir['rb_file_temp_*'].each{ |f| File.delete(f) }

    Dir.chdir(File::Temp::TMPDIR) do
      Dir['temp_*'].each{ |f| File.delete(f) }
      Dir['rb_file_temp_*'].each{ |f| File.delete(f) }
    end
  end
end

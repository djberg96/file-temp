######################################################################
# test_file_temp.rb
#
# Test suite for the file-temp library. These tests should be run
# via the 'rake test' task.
######################################################################
require 'rubygems'
require 'test-unit'
require 'file/temp'

class TC_File_Temp < Test::Unit::TestCase
  WINDOWS = File::ALT_SEPARATOR
  OSX = RbConfig::CONFIG['host_os'] =~ /darwin/i

  def setup
    @dir = File::Temp::TMPDIR
    @template = 'file-temp-test-XXXXX'
    @fh = nil

    # Because Dir[] doesn't work right with backslashes
    @dir = @dir.tr("\\", "/") if WINDOWS
  end

  test "library version is set to expected value" do
    assert_equal('1.3.0', File::Temp::VERSION)
  end

  # Fails with JRuby, not sure why.
  test "library works as expected with multiple threads" do
    threads = []
    assert_nothing_raised{ 100.times{ threads << Thread.new{ File::Temp.new }}}
    assert_nothing_raised{ threads.each{ |t| t.join } }
  end

  test "TMPDIR constant is defined" do
    assert_not_nil(File::Temp::TMPDIR)
    assert_kind_of(String, File::Temp::TMPDIR)
  end

  test "constructor works as expected with default auto delete option" do
    assert_nothing_raised{
      @fh = File::Temp.new
      @fh.print "hello"
      @fh.close
    }
  end

  test "constructor works as expected with false auto delete option" do
    assert_nothing_raised{
      @fh = File::Temp.new(false)
      @fh.print "hello"
      @fh.close
    }
  end

  test "constructor accepts and uses an optional template as expected" do
    assert_nothing_raised{ File::Temp.new(false, 'temp_foo_XXXXXX').close }
    assert_true(Dir["#{@dir}/temp_foo*"].length >= 1)
  end

  test "constructor with false auto delete and block works as expected" do
    assert_nothing_raised{ File::Temp.open(false, 'temp_foo_XXXXXX'){ |fh| fh.puts "hello" } }
    assert_true(Dir["#{@dir}/temp_foo*"].length >= 1)
  end

  test "second argument to constructor must be a string" do
    assert_raise(TypeError, ArgumentError){ @fh = File::Temp.new(false, 1) }
  end

  test "an error is raised if a custom template is invalid" do
    omit_if(OSX)
    assert_raise(Errno::EINVAL){ File::Temp.new(false, 'xx') }
  end

  test "constructor accepts a maximum of two arguments" do
    assert_raise(ArgumentError){ @fh = File::Temp.new(true, 'temp_bar_XXXXX', 1) }
  end

  test "temp_name basic functionality" do
    assert_respond_to(File::Temp, :temp_name)
    assert_nothing_raised{ File::Temp.temp_name }
    assert_kind_of(String, File::Temp.temp_name)
  end

  test "temp_name returns expected value" do
    if File::ALT_SEPARATOR
      assert_match(/^.*?\d*?tmp/, File.extname(File::Temp.temp_name))
    else
      assert_equal('.tmp', File.extname(File::Temp.temp_name))
    end
  end

  test "temp path basic functionality" do
    @fh = File::Temp.new
    assert_respond_to(@fh, :path)
  end

  test "temp path is nil if delete option is true" do
    @fh = File::Temp.new
    assert_nil(@fh.path)
  end

  test "temp path is not nil if delete option is false" do
    @fh = File::Temp.new(false)
    assert_not_nil(@fh.path)
  end

  test "ffi functions are private" do
    methods = File::Temp.methods(false).map{ |e| e.to_s }
    assert_false(methods.include?('_fileno'))
    assert_false(methods.include?('mkstemp'))
    assert_false(methods.include?('_umask'))
    assert_false(methods.include?('fclose'))
    assert_false(methods.include?('strerror'))
    assert_false(methods.include?('tmpnam'))
    assert_false(methods.include?('CloseHandle'))
    assert_false(methods.include?('CreateFileA'))
    assert_false(methods.include?('DeleteFileA'))
    assert_false(methods.include?('GetTempPathA'))
    assert_false(methods.include?('GetTempFileNameA'))
  end

  def teardown
    @dir = nil
    @template = nil
    @fh.close if @fh && !@fh.closed?
    @fh = nil

    Dir["temp_*"].each{ |f| File.delete(f) }
    Dir["rb_file_temp_*"].each{ |f| File.delete(f) }

    Dir.chdir(File::Temp::TMPDIR) do
      Dir["temp_*"].each{ |f| File.delete(f) }
      Dir["rb_file_temp_*"].each{ |f| File.delete(f) }
    end
  end
end

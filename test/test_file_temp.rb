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

  def setup
    @dir = File::Temp::TMPDIR
    @template = 'file-temp-test-XXXXX'
    @fh = nil

    # Because Dir[] doesn't work right with backslashes
    @dir = @dir.tr("\\", "/") if WINDOWS
  end

  def test_file_temp_version
    assert_equal('1.2.0', File::Temp::VERSION)
  end

  def test_file_temp_threaded
    threads = []
    assert_nothing_raised{ 100.times{ threads << Thread.new{ File::Temp.new }}}
    assert_nothing_raised{ threads.join }
  end

  def test_file_temp_tmpdir
    assert_not_nil(File::Temp::TMPDIR)
    assert_kind_of(String, File::Temp::TMPDIR)
  end

  def test_file_temp_auto_delete
    assert_nothing_raised{ @fh = File::Temp.new }
    assert_nothing_raised{ @fh.print "hello" }
    assert_nothing_raised{ @fh.close }
  end

  def test_file_temp_no_delete
    assert_nothing_raised{ @fh = File::Temp.new(false) }
    assert_nothing_raised{ @fh.print "hello" }
    assert_nothing_raised{ @fh.close }
    assert_true(Dir["#{@dir}/rb_file_temp*"].length == 1)
  end

  def test_file_temp_no_delete_with_template
    assert_nothing_raised{ File::Temp.new(false, 'temp_foo_XXXXXX').close }
    assert_true(Dir["#{@dir}/temp_foo*"].length >= 1)
  end

  def test_file_temp_no_delete_with_block
    assert_nothing_raised{ File::Temp.open(false, 'temp_foo_XXXXXX'){ |fh| fh.puts "hello" } }
    assert_true(Dir["#{@dir}/temp_foo*"].length >= 1)
  end

  def test_file_temp_expected_errors
    assert_raise(TypeError, ArgumentError){ @fh = File::Temp.new(false, 1) }
    assert_raise(ArgumentError){ @fh = File::Temp.new(true, 'temp_bar_XXXXX', 1) }
  end

  def test_file_temp_name_basic_functionality
    assert_respond_to(File::Temp, :temp_name)
    assert_nothing_raised{ File::Temp.temp_name }
    assert_kind_of(String, File::Temp.temp_name)
  end

  def test_file_temp_name
    assert_equal('.tmp', File.extname(File::Temp.temp_name))
  end

  def test_file_temp_path_basic_functionality
    @fh = File::Temp.new
    assert_respond_to(@fh, :path)
  end

  def test_file_temp_path_is_nil_if_delete_option_is_true
    @fh = File::Temp.new
    assert_nil(@fh.path)
  end

  def test_file_temp_path_is_not_nil_if_delete_option_is_false
    @fh = File::Temp.new(false)
    assert_not_nil(@fh.path)
  end

  def test_ffi_functions_are_private
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

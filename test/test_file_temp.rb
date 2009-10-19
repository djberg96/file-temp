######################################################################
# test_file_temp.rb
#
# Test suite for the file-temp library. These tests should be run
# via the 'rake test' task.
######################################################################
require 'rubygems'
gem 'test-unit'

require 'test/unit'
require 'file/temp'
require 'rbconfig'

class TC_File_Temp < Test::Unit::TestCase 
  def setup
    @dir = File::Temp::TMPDIR
    @template = 'file-temp-test-XXXXX'
    @fh = nil
  end

  def test_file_temp_version
    assert_equal('1.1.0', File::Temp::VERSION)
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
    assert_true(Dir["#{@dir}/rb_file_temp*"].length == 1)
    assert_nothing_raised{ @fh.print "hello" }
    assert_nothing_raised{ @fh.close }
  end

  def test_file_temp_no_delete_with_template
    assert_nothing_raised{ @fh = File::Temp.new(false, 'temp_foo_XXXXXX') }
    assert_true(Dir["#{@dir}/temp_foo*"].length == 1)
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

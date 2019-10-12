require 'java'
import java.lang.System

class File::Temp < File
  # The temporary directory used on MS Windows or Unix.
  TMPDIR = java.lang.System.getProperties["java.io.tmpdir"]

  # The name of the temporary file.
  attr_reader :path

  # Creates a new, anonymous, temporary file in your File::Temp::TMPDIR
  # directory.
  #
  # If the +delete+ option is set to true (the default) then the temporary file
  # will be deleted automatically as soon as all references to it are closed.
  # Otherwise, the file will live on in your File::Temp::TMPDIR path.
  #
  # If the +delete+ option is set to false, then the file is not deleted. In
  # addition, you can supply a string +template+ that the system replaces with
  # a unique filename. This template should end with 3 to 6 'X' characters.
  # The default template is 'rb_file_temp_XXXXXX'. In this case the temporary
  # file lives in the directory where it was created.
  #
  # Note that when using JRuby the template naming is not as strict, and the
  # trailing 'X' characters are simply replaced with the GUID that Java
  # generates for unique file names.
  #
  # Example:
  #
  #    fh = File::Temp.new(true, 'rb_file_temp_XXXXXX') => file
  #    fh.puts 'hello world'
  #    fh.close
  #
  def initialize(delete = true, template = 'rb_file_temp_XXXXXX')
    raise TypeError unless template.is_a?(String)

    # Since Java uses a GUID extension to generate a unique file name
    # we'll simply chop off the 'X' characters and let Java do the rest.
    template = template.sub(/_X{1,6}/, '_')

    # For consistency between implementations, convert errors here
    # to Errno::EINVAL.
    begin
      @file = java.io.File.createTempFile(template, nil)
    rescue NativeException => err
      raise SystemCallError.new(22), template # 22 is EINVAL
    end

    @file.deleteOnExit if delete

    path = @file.getName
    super(path, 'wb+')

    @path = path unless delete
  end

  # Generates a unique file name.
  #
  def self.temp_name
    file = java.io.File.createTempFile('rb_file_temp_', nil)
    file.deleteOnExit
    name = file.getName
    file.finalize
    name
  end

  # Identical to the File#close method except that we also finalize
  # the underlying Java File object.
  #
  def close
    super
    @file.finalize
  end
end

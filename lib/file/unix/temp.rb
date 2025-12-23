# frozen_string_literal: true

require 'ffi'
require 'tmpdir'
require 'securerandom'

# The File::Temp class encapsulates temporary files. It is a subclass of File.
class File::Temp < File
  extend FFI::Library
  ffi_lib FFI::Library::LIBC

  # :stopdoc:

  private

  attach_function :fclose, [:pointer], :int
  attach_function :_fileno, :fileno, [:pointer], :int
  attach_function :strerror, [:int], :string
  attach_function :tmpfile, [], :pointer
  attach_function :mkstemp, [:pointer], :int

  private_class_method :mkstemp, :strerror, :tmpfile
  private_class_method :fclose, :_fileno

  public

  # :startdoc:

  # The temporary directory used on MS Windows or Unix by default.
  TMPDIR = ENV['TEMP'] || ENV['TMP'] || ENV['TMPDIR'] || Dir.tmpdir

  # The name of the temporary file. Set to nil if the +delete+ option to the
  # constructor is true.
  attr_reader :path

  # Creates a new, anonymous, temporary file in your tmpdir, or whichever
  # directory you specifiy.
  #
  # If the +delete+ option is set to true (the default) then the temporary file
  # will be deleted automatically as soon as all references to it are closed.
  # Otherwise, the file will live on in your tmpdir path.
  #
  # If the +delete+ option is set to false, then the file is not deleted. In
  # addition, you can supply a string +template+ that the system replaces with
  # a unique filename. This template should end with 6 'X' characters.
  # The default template is 'rb_file_temp_XXXXXX'. In this case the temporary
  # file lives in the directory where it was created.
  #
  # The +template+ argument is ignored if the +delete+ argument is true.
  #
  # Example:
  #
  #    fh = File::Temp.new(delete: true, template: 'rb_file_temp_XXXXXX') => file
  #    fh.puts 'hello world'
  #    fh.close
  #
  def initialize(delete: true, template: 'rb_file_temp_XXXXXX', directory: TMPDIR, **options)
    @fptr = nil

    if delete
      @fptr = tmpfile()
      raise SystemCallError.new('tmpfile', FFI.errno) if @fptr.null?
      fd = _fileno(@fptr)
    else
      unless template.is_a?(String)
        raise TypeError, "template must be a String"
      end

      unless template.end_with?('XXXXXX')
        raise ArgumentError, "template must end with 6 'X' characters"
      end

      begin
        omask = File.umask(077)
        full_template = File.join(directory, template)
        ptr = FFI::MemoryPointer.from_string(full_template)
        fd = mkstemp(ptr)

        if fd < 0
          raise SystemCallError.new('mkstemp', FFI.errno)
        end

        @path = ptr.read_string
      ensure
        File.umask(omask)
      end
    end

    options[:mode] ||= 'wb+'

    super(fd, **options)
  end

  # The close method was overridden to ensure the internal file pointer that we
  # potentially created in the constructor is closed. It is otherwise identical
  # to the File#close method.
  #--
  # This is probably unnecessary since Ruby will close the fd, and in reality
  # the fclose function probably fails with an Errno::EBADF. Consequently
  # I will let it silently fail as a no-op.
  #
  def close
    super
    fclose(@fptr) if @fptr && !@fptr.null?
  end

  # Generates a unique file name.
  #
  # Note that a file is not actually generated on the filesystem.
  #
  def self.temp_name
    File.join(TMPDIR, "tmp.#{SecureRandom.hex(8)}.tmp")
  end
end

require 'ffi'
require 'tmpdir'

class File::Temp < File
  extend FFI::Library

  # :stopdoc:

  private

  if File::ALT_SEPARATOR
    ffi_lib 'msvcrt'

    attach_function :_close, [:int], :int
    attach_function :fclose, [:pointer], :int
    attach_function :_fdopen, [:int, :string], :pointer
    attach_function :_fileno, [:pointer], :int
    attach_function :_mktemp, [:string], :string
    attach_function :_open, [:string, :int, :int], :int
    attach_function :_open_osfhandle, [:long, :int], :int
    attach_function :tmpnam, [:string], :string
    attach_function :_umask, [:int], :int

    ffi_lib 'kernel32'

    attach_function :CloseHandle, [:long], :bool
    attach_function :CreateFileA, [:string, :ulong, :ulong, :pointer, :ulong, :ulong, :ulong], :long
    attach_function :DeleteFileA, [:string], :bool
    attach_function :FormatMessageA, [:long, :long, :long, :long, :pointer, :long, :pointer], :long
    attach_function :GetLastError, [], :int
    attach_function :GetTempPathA, [:long, :pointer], :long
    attach_function :GetTempFileNameA, [:string, :string, :uint, :pointer], :uint

    private_class_method :_close, :_fdopen, :_mktemp, :_open, :_open_osfhandle
    private_class_method :CloseHandle, :CreateFileA, :DeleteFileA, :FormatMessageA
    private_class_method :GetLastError, :GetTempPathA, :GetTempFileNameA

    S_IWRITE      = 128
    S_IREAD       = 256
    BINARY        = 0x8000
    SHORT_LIVED   = 0x1000
    GENERIC_READ  = 0x80000000
    GENERIC_WRITE = 0x40000000
    CREATE_ALWAYS = 2

    FORMAT_MESSAGE_FROM_SYSTEM    = 0x00001000
    FORMAT_MESSAGE_ARGUMENT_ARRAY = 0x00002000

    FILE_ATTRIBUTE_NORMAL     = 0x00000080
    FILE_FLAG_DELETE_ON_CLOSE = 0x04000000
    INVALID_HANDLE_VALUE      = -1
  else
    ffi_lib FFI::Library::LIBC

    attach_function :fclose, [:pointer], :int
    attach_function :_fileno, :fileno, [:pointer], :int
    attach_function :mkstemp, [:string], :int
    attach_function :strerror, [:int], :string
    attach_function :tmpfile, [], :pointer
    attach_function :tmpnam, [:string], :string
    attach_function :_umask, :umask, [:int], :int

    private_class_method :mkstemp, :strerror, :tmpfile
  end

  private_class_method :fclose, :_fileno, :tmpnam, :_umask

  public

  # :startdoc:

  # The version of the file-temp library.
  VERSION = '1.2.0'

  # The temporary directory used on MS Windows or Unix.
  if File::ALT_SEPARATOR
    TMPDIR = ENV['TEMP'] || ENV['TMP'] || ENV['USERPROFILE'] || Dir.tmpdir
  else
    TMPDIR = ENV['TEMP'] || ENV['TMP'] || ENV['TMPDIR'] || Dir.tmpdir
  end

  # The name of the file. This is only retained if the first argument to the
  # constructor is false.
  attr_reader :path

  # Creates a new, anonymous, temporary file in your File::Temp::TMPDIR
  # directory
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
  # The +template+ argument is ignored if the +delete+ argument is true.
  #
  # Example:
  #
  #    fh = File::Temp.new(true, 'rb_file_temp_XXXXXX') => file
  #    fh.puts 'hello world'
  #    fh.close
  #
  def initialize(delete = true, template = 'rb_file_temp_XXXXXX')
    @fptr = nil

    if delete
      @fptr = tmpfile()
      fd = _fileno(@fptr)
    else
      begin
        if File::ALT_SEPARATOR
          template = _mktemp(template)

          if template.nil?
            raise SystemCallError, '_mktemp function failed: ' + get_error
          end
        end

        omask = _umask(077)

        @path = File.join(TMPDIR, template)
        fd = mkstemp(@path)

        if fd < 0
          raise SystemCallError, 'mkstemp function failed: ' + get_error
        end
      ensure
        _umask(omask)
      end
    end

    super(fd, 'wb+')
  end

  # The close method was overridden to ensure the internal file pointer we
  # created in the constructor is closed. It is otherwise identical to the
  # File#close method.
  #
  def close
    super
    fclose(@fptr) if @fptr
  end

  # Generates a unique file name.
  #
  # Note that a file is not actually generated on the filesystem.
  #
  def self.temp_name
    if File::ALT_SEPARATOR
      TMPDIR + tmpnam(nil) << '.tmp'
    else
      tmpnam(nil) << '.tmp'
    end
  end

  private

  def get_error
    if File::ALT_SEPARATOR
      errno  = GetLastError()
      buffer = FFI::MemoryPointer.new(:char, 512)
      flags  = FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ARGUMENT_ARRAY

      FormatMessageA(flags, 0, errno, 0, buffer, buffer.size, nil)

      buf.read_string
    else
      strerror(FFI.errno)
    end
  end

  if File::ALT_SEPARATOR
    def get_temp_path
      buf = FFI::MemoryPointer.new(:char, 1024)

      if GetTempPathA(buf.size, buf) == 0
        raise SystemCallError, 'GetTempPath function failed: ' + get_error
      end

      buf.read_string.chop # remove trailing slash
    end

    # The version of tmpfile() implemented by Microsoft is unacceptable.
    # It attempts to write to C:\ (root) instead of a temporary directory.
    # This is not only bad behavior, it won't work on Windows 7 and later
    # without admin rights due to security restrictions.
    #
    # This is a custom implementation based on some code from the Cairo
    # project.
    #
    def tmpfile
      file_name = get_temp_path()
      buf = FFI::MemoryPointer.new(:char, 1024)

      if GetTempFileNameA(file_name, 'rb_', 0, buf) == 0
        raise SystemCallError, 'GetTempFileName function failed: ' + get_error
      end

      file_name = buf.read_string

      handle = CreateFileA(
        file_name,
        GENERIC_READ | GENERIC_WRITE,
        0,
        nil,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL | FILE_FLAG_DELETE_ON_CLOSE,
        0
      )

      if handle == INVALID_HANDLE_VALUE
        DeleteFileA(file_name)
        raise SystemCallError, 'CreateFile function failed: ' + get_error
      end

      fd = _open_osfhandle(handle, 0)

      if fd < 0
        CloseHandle(handle)
        raise SystemCallError, 'open_osfhandle function failed: ' + get_error
      end

      fp = _fdopen(fd, 'w+b')

      if fp.nil?
        _close(fd)
        raise SystemCallError, 'fdopen function failed: ' + get_error
      end

      fp
    end

    # The MS C runtime does not define a mkstemp() function, so we've
    # created one here.
    #
    def mkstemp(template)
      flags = RDWR | BINARY | CREAT | EXCL | SHORT_LIVED
      pmode = S_IREAD | S_IWRITE

      fd = _open(template, flags, pmode)

      if fd < 0
        raise SystemCallError, 'mkstemp function failed: ' + get_error
      end

      fd
    end
  end
end

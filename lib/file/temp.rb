require 'rbconfig'
require 'ffi'

class File::Temp < File
  extend FFI::Library

  private

  # True if operating system is MS Windows
  WINDOWS = Config::CONFIG['host_os'] =~ /mswin|win32|dos|cygwin|mingw/i

  if WINDOWS
    ffi_lib 'msvcrt'  

    attach_function '_fileno', [:pointer], :int
    attach_function '_umask', [:int], :int
    attach_function '_open', [:string, :int, :int], :int

    S_IWRITE = 128 # write permission, owner
    S_IREAD  = 256 # read permission, owner
    
    BINARY      = 0x8000 # binary mode
    SHORT_LIVED = 0x1000 # temporary storage, try not to flush
  else
    attach_function 'fileno', [:pointer], :int
    attach_function 'mkstemp', [:string], :int
    attach_function 'umask', [:int], :int
    attach_function 'tmpfile', [], :pointer
  end

  attach_function 'fclose', [:pointer], :int
  attach_function 'tmpnam', [:string], :string

  public

  # The version of the file-temp library.
  VERSION = '1.1.0'

  if WINDOWS
    # The temporary directory used on your system.
    TMPDIR = ENV['TEMP'] || ENV['TMP'] || ENV['TMPDIR'] || "C:\\Windows\\Temp"
  else
    # The temporary directory used on your system.
    TMPDIR = ENV['TEMP'] || ENV['TMP'] || ENV['TMPDIR'] || '/tmp'
  end

  public

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
  #--
  # TODO: We're going to have to ditch tmpfile() on MS Windows because it
  # stupidly creates files in C:/ (root) instead of a temporary directory.
  # Windows 7 and later will not allow this without admin rights.
  #
  # See http://cgit.freedesktop.org/cairo/commit/?id=4fa46e3caaffb54f4419887418d8d0ea39816092
  # for a possible solution.
  #
  def initialize(delete = true, template = 'rb_file_temp_XXXXXX')
    @fptr = nil

    if delete
      @fptr = tmpfile()
      fd = WINDOWS ? _fileno(@fptr) : fileno(@fptr)
    else
      begin
        omask = WINDOWS ? _umask(077) : umask(077)
        fd = mkstemp(File.join(TMPDIR, template))
        raise SystemCallError, 'mkstemp()' if fd < 0
      ensure
        WINDOWS ? _umask(omask) : umask(omask)
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

  # Generates a unique file name, prefixed with the value of the
  # File::Temp::TMPDIR constant.
  #
  # Note that a file is not actually generated on the filesystem.
  #
  def self.temp_name
    TMPDIR + tmpnam(nil) << '.tmp'
  end

  private

  # The MS C runtime does not define a mkstemp() function, so we've
  # created one here.
  #
  if WINDOWS
    # The version of tmpfile() that ships with MS Windows has security
    # issues on Windows 7 and later, along with undesirable behavior in
    # general. This is a custom implementation modeled on some code from
    # the Cairo project.
    #--
    # TODO: Add needed function definitions and tests.
    #
    def tmpfile
      buf = 0.chr * 1024 

      if GetTempPathW(buf.length, buf) == 0
        raise SystemCallError, 'GetTempPath()'
      end

      file_name = buf.strip
      buf = 0.chr * 1024

      if GetTempFileNameW(file_name, 'rb_', 0, buf) == 0
        raise SystemCallError, 'GetTempFileName()'
      end

      file_name = buf.strip

      handle = CreateFileW(
        file_name,
        GENERIC_READ | GENERIC_WRITE,
        0,
        nil,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL | FILE_FLAG_DELETE_ON_CLOSE,
        nil 
      )

      if handle == INVALID_HANDLE_VALUE
        DeleteFileW(file_name)
        raise SystemCallError, 'CreateFileW()'
      end

      fd = _open_osfhandle(handle, 0)

      if fd < 0
        CloseHandle(handle)
        raise SystemCallError, 'open_osfhandle()'
      end

      fp = _fdopen(fd, 'w+b')

      if fp.nil?
        _close(fd)
        raise SystemCallError, 'fdopen()'
      end

      fp
    end

    def mkstemp(template)
      flags = RDWR | BINARY | CREAT | EXCL | SHORT_LIVED
      pmode = S_IREAD | S_IWRITE

      fd = _open(template, flags, pmode)
      
      raise SystemCallError, 'mkstemp()' if fd < 0
      
      fd
    end
  end
end

# For backwards compatability
FileTemp = File::Temp

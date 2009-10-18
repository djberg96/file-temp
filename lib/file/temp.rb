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
  end

  attach_function 'fclose', [:pointer], :int
  attach_function 'tmpfile', [], :pointer
  attach_function 'tmpnam', [:string], :string

  public

  # The version of the file-temp library.
  VERSION = '1.1.0'

  if WINDOWS
    # The temporary directory used on your system.
    TMPDIR = ENV['TEMP'] || ENV['TMP'] || "C:\\Windows\\Temp"
  else
    # The temporary directory used on your system.
    TMPDIR = ENV['TEMP'] || ENV['TMP'] || '/tmp'
  end

  public

  # Creates a new, anonymous temporary file in your File::Temp::TMPDIR
  # directory, or /tmp if that cannot be accessed. If your $TMPDIR environment
  # variable is set, it will be used instead. If $TMPDIR is not writable by
  # the process, it will resort back to File::Temp::TMPDIR or /tmp.
  #
  # If the +delete+ option is set to true (the default) then the temporary file
  # will be deleted automatically as soon as all references to it are closed.
  # Otherwise, the file will live on in your $TMPDIR.
  #
  # If the +delete+ option is set to false, then the file is *not* deleted. In
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
      fd = WINDOWS ? _fileno(@fptr) : fileno(@fptr)
    else
      begin
        omask = WINDOWS ? _umask(077) : umask(077)
        fd = mkstemp(template)
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

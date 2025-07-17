# frozen_string_literal: true

require 'ffi'
require 'tmpdir'

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
  attach_function :tmpnam, [:pointer], :string
  attach_function :mktemp, [:pointer], :string

  private_class_method :mktemp, :strerror, :tmpfile
  private_class_method :tmpnam, :fclose, :_fileno

  public

  # :startdoc:

  # The temporary directory used on Unix by default.
  # Falls back through multiple environment variables to find a suitable temp directory.
  TMPDIR = (ENV['TMPDIR'] || ENV['TMP'] || ENV['TEMP'] || Dir.tmpdir).tap do |dir|
    unless Dir.exist?(dir)
      warn "Warning: Temporary directory #{dir} does not exist, falling back to /tmp"
      break '/tmp'
    end
  end.freeze

  # The name of the temporary file. Set to nil if the +delete+ option to the
  # constructor is true.
  attr_reader :path

  # Creates a new, anonymous, temporary file in your tmpdir, or whichever
  # directory you specify.
  #
  # If the +delete+ option is set to true (the default) then the temporary file
  # will be deleted automatically as soon as all references to it are closed.
  # Otherwise, the file will live on in your tmpdir path.
  #
  # If the +delete+ option is set to false, then the file is not deleted. In
  # addition, you can supply a string +template+ that the system replaces with
  # a unique filename. This template should end with 3 to 6 'X' characters.
  # The default template is 'rb_file_temp_XXXXXX'. In this case the temporary
  # file lives in the directory where it was created.
  #
  # The +template+ argument is ignored if the +delete+ argument is true.
  #
  # @param delete [Boolean] Whether to automatically delete the file on close
  # @param template [String] Template for filename when delete is false
  # @param directory [String] Directory to create the file in
  # @param options [Hash] Additional file options
  #
  # @raise [ArgumentError] if template is not a string or invalid
  # @raise [SystemCallError] if file creation fails
  #
  # Example:
  #
  #    fh = File::Temp.new(delete: true, template: 'rb_file_temp_XXXXXX')
  #    fh.puts 'hello world'
  #    fh.close
  #
  def initialize(delete: true, template: 'rb_file_temp_XXXXXX', directory: TMPDIR, **options)
    # Validate inputs - maintain backward compatibility with original error types
    raise TypeError, 'template must be a string' unless template.is_a?(String)
    raise ArgumentError, 'directory must be a string' unless directory.is_a?(String)

    @fptr = nil

    if delete
      @fptr = tmpfile()
      if @fptr.null?
        error_msg = strerror(FFI.errno)
        raise SystemCallError.new("tmpfile failed: #{error_msg}", FFI.errno)
      end
      fd = _fileno(@fptr)
    else
      create_named_temp_file(template, directory)
    end

    options[:mode] ||= 'wb+'

    if delete
      super(fd, **options)
    else
      super(@path, **options)
    end
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
    close_file_pointer
  end

  # Generates a unique file name.
  #
  # Note that a file is not actually generated on the filesystem.
  #
  # @return [String] A unique temporary filename
  def self.temp_name
    name = tmpnam(nil)
    return "#{name}.tmp" if name && !name.empty?

    # Fallback if tmpnam fails
    "tmp_#{Time.now.to_f}_#{Process.pid}.tmp"
  end

  # Returns true if the given path looks like a valid temporary file template
  #
  # @param template [String] The template to validate
  # @return [Boolean] true if template appears valid
  def self.valid_template?(template)
    return false unless template.is_a?(String)
    return false if template.empty?

    # Should end with 3-6 X characters
    template.match?(/X{3,6}\z/)
  end

  private

  # Creates a named temporary file using mktemp
  def create_named_temp_file(template, directory)
    # Ensure directory exists and is writable
    unless Dir.exist?(directory)
      raise ArgumentError, "Directory #{directory} does not exist"
    end

    unless File.writable?(directory)
      raise ArgumentError, "Directory #{directory} is not writable"
    end

    omask = File.umask(077)
    ptr = FFI::MemoryPointer.from_string(template)
    str = mktemp(ptr)

    if str.nil? || str.empty?
      # Let the original errno propagate for backward compatibility
      raise SystemCallError.new('mktemp', FFI.errno)
    end

    @path = File.join(directory, ptr.read_string)
  ensure
    File.umask(omask) if omask
  end

  # Safely closes the file pointer if it exists
  def close_file_pointer
    return unless @fptr && !@fptr.null?

    begin
      fclose(@fptr)
    rescue SystemCallError
      # Ignore errors as this is a cleanup operation and the fd
      # may already be closed by Ruby's garbage collector
    ensure
      @fptr = nil
    end
  end
end

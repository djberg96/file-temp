require 'java'
import java.lang.System

class File::Temp < File
  VERSION = '1.2.2'

  TMPDIR = System.getProperties["java.io.tmpdir"]

  attr_reader :path

  def initialize(delete = true, template = 'rb_file_temp_XXXXXX')
    raise TypeError unless template.is_a?(String)

    template = template.sub(/_X{1,6}/, '_')

    @file = java.io.File.createTempFile(template, nil)
    @file.deleteOnExit if delete

    @path = @file.getName unless delete

    super(@file.getName, 'wb+')
  end

  def self.temp_name
    file = java.io.File.createTempFile('rb_file_temp_', nil)
    file.deleteOnExit
    file.getName
  end

  def close
    super
    @file.finalize
  end
end

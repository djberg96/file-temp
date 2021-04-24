# frozen_string_literal: true

class File::Temp < File
  # The version of the file-temp library
  VERSION = '1.7.1'
end

if RUBY_PLATFORM == 'java'
  require_relative 'java/temp'
else
  if File::ALT_SEPARATOR
    require_relative 'windows/temp'
  else
    require_relative 'unix/temp'
  end
end

if RUBY_PLATFORM == 'java'
  require_relative 'java/temp'
else
  if File::ALT_SEPARATOR
    require_relative 'windows/temp'
  else
    require_relative 'unix/temp'
  end
end

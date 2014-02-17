if RUBY_PLATFORM == 'java'
  require File.join(File.expand_path(File.dirname(__FILE__)), 'temp_java')
else
  require File.join(File.expand_path(File.dirname(__FILE__)), 'temp_c')
end

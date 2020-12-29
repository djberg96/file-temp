## 1.7.1 - 28-Dec-2020
* Updated file option kwarg handling so that it's compatible with Ruby 3.x.
* Switched from rdoc to markdown format since github isn't rendering rdoc properly.
* Fixed up one of the specs.

## 1.7.0 - 1-Jul-2020
* Replaced test-unit with rspec, and updated the tests.
* Updated ffi dependency to 1.1.x.
* Removed some archiving options from the Rakefile that I wasn't using.

## 1.6.0 - 9-May-2020
* Added an +options+ argument that is passed along as options to the the
  underlying File.new constructor.

## 1.5.0 - 8-May-2020
* Switched to keyword arguments.
* Added the ability to specify a tmp directory.
* Updates to the JRuby version, removed some code that no longer worked, and
  added support for specifying your own directory.
* Added a LICENSE file to the distro as part of the Apache-2.0 requirement.
* Added explicit .rdoc extensions to the README, CHANGES and MANIFEST files.

## 1.4.0 - 12-Oct-2019
* Changed license to Apache-2.0.
* VERSION constant now lives in a single place, and is frozen.
* Added metadata to the gemspec.
* Updated cert.

## 1.3.0 - 9-Apr-2016
* This gem is now signed.
* Added a file-temp.rb file for convenience.
* The gem tasks in the Rakefile now assume Rubygems 2.x.
* Some gemspec updates, removed rubyforge_project, added a cert.
* Skip one test on OSX since it's an issue with the underlying C function.
* Reorganized internal directory layout so Windows, Unix and Java versions
  are each in their own directory and have their own versions for ease
  of maintenance.

## 1.2.1 - 17-Feb-2014
* There is now a completely separate implementation for JRuby that uses the
  Java API instead of C. It uses a GUID to create the temporary file name
  instead of the 'XXXXXX' template, but is otherwise identical in function.
* Reworked the error handling. The posix functions now use a combination
  of SystemCallError and FFI.errno, except on Windows, which uses _get_errno
  instead for the posix compatible functions.
* Refactored the tests to use declarative syntax and added one test for
  invalid templates.
* Removed the internal mkstemp function for Windows, no longer needed.
* Use tmpnam_s on Windows instead of tmpnam.
* Use wide character functions on Windows.

## 1.2.0 - 10-Apr-2012
* Removed the old FileTemp alias for File::Temp. It was deprecated and
  has now been officially removed.
* Some refactoring of the custom internal Windows functions.
* Nicer error handling if certain FFI functions fail.
* Made the FFI functions private.

## 1.1.5 - 17-Jul-2011
* Now stores file path information if the file is retained on the filesystem.
  Thanks go to joerixaop for the patch.
* The TMPDIR fallback determination on Windows is no longer hard coded.

## 1.1.4 - 16-Sep-2010
* The File::Temp.temp_name method has been altered on Unix systems. It
  no longer prefixes TMPDIR to the name since it was redundant and could
  generate a bogus path.
* Set the license to Artistic 2.0.
* Set the test task as the default Rake task.

## 1.1.3 - 14-Sep-2010
* Fixed potential libc linker failure.

## 1.1.2 - 28-Apr-2010
* Explicitly link against libc for Unix versions.
* Refactored the Rakefile. An old install task was removed and the gem
  related tasks were placed under the 'gem' namespace.

## 1.1.1 - 24-Oct-2009
* Removed the 'use' library as a dependency.

## 1.1.0 - 21-Oct-2009
* Now pure Ruby, using FFI.
* Fixed RF Bug #26757 - FILE pointer leak. Thanks go to Eric Wong for the spot.
* Renamed and refactored the test file slightly.
* Updated the gemspec.

## 1.0.0 - 12-Apr-2008
* Added security via umask().
* Version bump to 1.0.0.

## 0.1.2 - 6-Jun-2007
* Gemspec fix (forgot the temp.h file - oops).
* Added an extra test.
 
## 0.1.1 - 2-Jun-2007
* Core code and test case now work properly on MS Windows.
* Now uses MS VC++ 8 functions when available (tmpfile_s, _sopen_s).

## 0.1.0 - 1-Jun-2007
* Initial release.

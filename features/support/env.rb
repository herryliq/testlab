require 'aruba/cucumber'

ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"
LIB_DIR = File.join(File.expand_path(File.dirname(__FILE__)),'..','..','lib')

TEST_ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
TEST_REPO = File.dirname(__FILE__)

if %w( vagrant travis ).include?(ENV['USER'])
  TEST_LABFILE = File.join(TEST_REPO, 'Labfile.bare-metal')
else
  TEST_LABFILE = File.join(TEST_REPO, 'Labfile.vagrant')
end


Before do
  # Using "announce" causes massive warnings on 1.9.2
  @aruba_timeout_seconds = 3600
  @puts = true
  @original_rubylib = ENV['RUBYLIB']
  ENV['RUBYLIB'] = LIB_DIR + File::PATH_SEPARATOR + ENV['RUBYLIB'].to_s
  # ENV['VAGRANT_HOME'] = File.join("", "tmp", ".vagrant.d")
end

After do
  ENV['RUBYLIB'] = @original_rubylib
end

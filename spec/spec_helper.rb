################################################################################
#
#      Author: Zachary Patten <zachary AT jovelabs DOT com>
#   Copyright: Copyright (c) Zachary Patten
#     License: Apache License, Version 2.0
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
################################################################################
require 'coveralls'
Coveralls.wear!
################################################################################
require 'testlab'

REPO_DIR     = File.join(File.dirname(__FILE__), 'support')
LABFILE_PATH = File.join(REPO_DIR, 'Labfile')

RSpec.configure do |config|
  config.before(:each) do
    TestLab::Node.purge
    TestLab::Container.purge
    TestLab::Network.purge
    TestLab::Interface.purge
    TestLab::User.purge

    ZTK::SSH.any_instance.stub(:file).and_yield(StringIO.new)
    ZTK::SSH.any_instance.stub(:exec) { OpenStruct.new(:output => "", :exit_code => 0) }
    ZTK::SSH.any_instance.stub(:bootstrap) { "" }
    ZTK::SSH.any_instance.stub(:upload) { true }
    ZTK::SSH.any_instance.stub(:download) { true }

    ZTK::Command.any_instance.stub(:exec) { OpenStruct.new(:output => "", :exit_code => 0) }

    ZTK::TCPSocketCheck.any_instance.stub(:wait) { true }
  end
end

def ui_helper(options={})
  ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
end

def testlab_helper(options={})
  TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => options[:ui])
end

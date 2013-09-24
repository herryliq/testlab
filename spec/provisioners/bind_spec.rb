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
require "spec_helper"

describe TestLab::Provisioner::Bind do

  subject {
    @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
    @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
    @testlab.boot
    TestLab::Container.first('server-bind')
  }

  describe "class" do

    it "should be an instance of TestLab::Provisioner::Bind" do
      subject.provisioners.last.new(subject.config, @ui).should be_an_instance_of TestLab::Provisioner::Bind
    end

  end

  describe "methods" do

    before(:each) do
      ZTK::SSH.any_instance.stub(:file).and_yield(StringIO.new)
      ZTK::SSH.any_instance.stub(:exec) { OpenStruct.new(:output => "", :exit_code => 0) }
      ZTK::SSH.any_instance.stub(:bootstrap) { "" }
    end

    context "provision" do

      it "should provision a node" do
        p = TestLab::Provisioner::Bind.new(subject.config, @ui)
        p.on_node_provision(subject.node)
      end

      it "should provision a network" do
        p = TestLab::Provisioner::Bind.new(subject.config, @ui)
        p.on_network_provision(subject.primary_interface.network)
      end

      it "should provision a container" do
        p = TestLab::Provisioner::Bind.new(subject.config, @ui)
        p.on_container_provision(subject)
      end

    end

  end

end

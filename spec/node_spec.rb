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

describe TestLab::Node do

  subject {
    @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
    @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
    @testlab.boot
    @testlab.nodes.first
  }

  describe "class" do

    it "should be an instance of TestLab::Node" do
      subject.should be_an_instance_of TestLab::Node
    end

  end

  describe "methods" do

    describe "template_dir" do
      it "should return the path to the node template directory" do
        subject.class.template_dir.should == "#{TestLab.gem_dir}/lib/testlab/node/templates"
      end
    end

    describe "#status" do
      it "should return a hash of status information about the node" do
        subject.instance_variable_get(:@provider).stub(:state) { :not_created }
        subject.status.should be_kind_of(Hash)
        subject.status.should_not be_empty
      end
    end

    describe "#lxc" do
      it "should return an instance of LXC configured for this node" do
        subject.lxc.should be_kind_of(LXC)
        subject.lxc.should_not be_nil
      end
    end

    describe "#arch" do
      it "should return the machine architecture of the node" do
        subject.ssh.stub(:exec) { OpenStruct.new(:output => "x86_64") }
        subject.arch.should be_kind_of(String)
        subject.arch.should_not be_empty
      end
    end

    describe "#create" do
      it "should create the node" do
        subject.instance_variable_get(:@provider).stub(:create) { true }
        subject.stub(:state) { :not_created }
        subject.stub(:provisioners) { Array.new }

        subject.create
      end
    end

    describe "#destroy" do
      it "should destroy the node" do
        subject.instance_variable_get(:@provider).stub(:destroy) { true }
        subject.stub(:state) { :stopped }
        subject.stub(:provisioners) { Array.new }

        subject.destroy
      end
    end

    describe "#up" do
      it "should online the node" do
        subject.instance_variable_get(:@provider).stub(:up) { true }
        subject.stub(:state) { :stopped }
        subject.stub(:provisioners) { Array.new }

        subject.up
      end
    end

    describe "#down" do
      it "should offline the node" do
        subject.instance_variable_get(:@provider).stub(:down) { true }
        subject.stub(:state) { :running }
        subject.stub(:provisioners) { Array.new }

        subject.down
      end
    end

    describe "provision" do
      it "should provision the node" do
        subject.stub(:state) { :running }
        subject.stub(:provisioners) { Array.new }

        subject.provision
      end
    end

    describe "deprovision" do
      it "should deprovision the node" do
        subject.stub(:state) { :running }
        subject.stub(:provisioners) { Array.new }

        subject.deprovision
      end
    end

    describe "#build" do
      it "should build the node" do
        subject.stub(:create) { true }
        subject.stub(:up) { true }
        subject.stub(:provision) { true }

        subject.build.should == true
      end
    end

    describe "#demolish" do
      it "should demolish the node" do
        subject.stub(:destroy) { true }
        subject.stub(:down) { true }
        subject.stub(:deprovision) { true }

        subject.demolish.should == true
      end
    end

    describe "#recycle" do
      it "should recycle the node" do
        subject.stub(:demolish) { true }
        subject.stub(:build) { true }

        subject.recycle.should == true
      end
    end

    describe "#bounce" do
      it "should bounce the node" do
        subject.stub(:down) { true }
        subject.stub(:up) { true }

        subject.bounce.should == true
      end
    end

  end

end

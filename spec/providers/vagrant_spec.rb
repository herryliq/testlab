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

describe TestLab::Provider::Vagrant do

  subject {
    @ui = ui_helper
    @testlab = testlab_helper(:ui => @ui)
    @testlab.boot
    @testlab.nodes.first
  }

  before(:each) do
    ZTK::Command.any_instance.stub(:exec) { OpenStruct.new(:output => "", :exit_code => 0) }
    ZTK::TCPSocketCheck.any_instance.stub(:wait) { true }
  end

  describe "class" do

    it "should be an instance of TestLab::Provider::Vagrant" do
      subject.provider.should be TestLab::Provider::Vagrant
      subject.instance_variable_get("@provider").should be_an_instance_of TestLab::Provider::Vagrant
    end

  end

  describe "methods" do

    describe "create" do
      it "should return true" do
        subject.instance_variable_get("@provider").create.should == true
      end
    end

    describe "destroy" do
      it "should return true" do
        subject.instance_variable_get("@provider").destroy.should == true
      end
    end

    describe "up" do
      it "should return true" do
        subject.instance_variable_get("@provider").up.should == true
      end
    end

    describe "down" do
      it "should return true" do
        subject.instance_variable_get("@provider").down.should == true
      end
    end

    describe "reload" do
      it "should return true" do
        subject.instance_variable_get("@provider").reload.should == true
      end
    end

  end

end

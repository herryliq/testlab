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

describe TestLab do

  subject {
    @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
    @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
    @testlab.boot
    @testlab
  }

  describe "class" do

    it "should be an instance of TestLab" do
      subject.should be_an_instance_of TestLab
    end

  end

  describe "methods" do

    before(:each) do
      TestLab::Node.any_instance.stub(:state) { :running }
    end

    describe "#config" do
      it "should return the configuration hash for the lab" do
        subject.config.should be_kind_of Hash
      end
    end

    describe "#alive?" do
      it "should return true if the lab is alive" do
        subject.alive?.should == true
      end
    end

    describe "#dead?" do
      it "should return false if the lab is alive" do
        subject.dead?.should == false
      end
    end

    describe "#create" do
      it "should online the lab" do
        TestLab::Node.any_instance.stub(:create) { true }
        TestLab::Container.any_instance.stub(:create) { true }
        TestLab::Network.any_instance.stub(:create) { true }

        subject.create
      end
    end

    describe "#destroy" do
      it "should offline the lab" do
        TestLab::Node.any_instance.stub(:destroy) { true }
        TestLab::Container.any_instance.stub(:destroy) { true }
        TestLab::Network.any_instance.stub(:destroy) { true }

        subject.destroy
      end
    end

    describe "#up" do
      it "should online the lab" do
        TestLab::Node.any_instance.stub(:up) { true }
        TestLab::Container.any_instance.stub(:up) { true }
        TestLab::Network.any_instance.stub(:up) { true }

        subject.up
      end
    end

    describe "#down" do
      it "should offline the lab" do
        TestLab::Node.any_instance.stub(:down) { true }
        TestLab::Container.any_instance.stub(:down) { true }
        TestLab::Network.any_instance.stub(:down) { true }

        subject.down
      end
    end

    describe "#provision" do
      it "should provision the lab" do
        TestLab::Node.any_instance.stub(:provision) { true }
        TestLab::Container.any_instance.stub(:provision) { true }
        TestLab::Network.any_instance.stub(:provision) { true }

        subject.provision
      end
    end

    describe "#deprovision" do
      it "should deprovision the lab" do
        TestLab::Node.any_instance.stub(:deprovision) { true }
        TestLab::Container.any_instance.stub(:deprovision) { true }
        TestLab::Network.any_instance.stub(:deprovision) { true }

        subject.deprovision
      end
    end

    describe "#build" do
      it "should build the lab" do
        TestLab::Node.any_instance.stub(:build) { true }
        TestLab::Container.any_instance.stub(:build) { true }
        TestLab::Network.any_instance.stub(:build) { true }

        subject.build
      end
    end

    describe "#demolish" do
      it "should demolish the lab" do
        TestLab::Node.any_instance.stub(:demolish) { true }
        TestLab::Container.any_instance.stub(:demolish) { true }
        TestLab::Network.any_instance.stub(:demolish) { true }

        subject.demolish
      end
    end

    describe "#bounce" do
      it "should bounce the lab" do
        subject.stub(:down) { true }
        subject.stub(:up) { true }

        subject.bounce
      end
    end

    describe "#recycle" do
      it "should recycle the lab" do
        subject.stub(:demolish) { true }
        subject.stub(:build) { true }

        subject.recycle
      end
    end

  end


end

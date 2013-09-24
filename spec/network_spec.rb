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

describe TestLab::Network do

  subject {
    @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
    @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
    @testlab.boot
    @testlab.networks.first
  }

  describe "class" do

    it "should be an instance of TestLab::Network" do
      subject.should be_an_instance_of TestLab::Network
    end

  end

  describe "methods" do

    describe "ips" do
      it "should return the ips for all defined containers" do
        subject.class.ips.should be_kind_of(Array)
        subject.class.ips.should_not be_empty
        subject.class.ips.should == ["100.64.0.254"]
      end
    end

    describe "#ptr" do
      it "should return a BIND PTR record for the networks bridge interface" do
        subject.ptr.should be_kind_of(String)
        subject.ptr.should_not be_empty
        subject.ptr.should == "254"
      end
    end

    describe "#arpa" do
      it "should return the ARPA network calculated from the cidr address" do
        subject.arpa.should be_kind_of(String)
        subject.arpa.should_not be_empty
        subject.arpa.should == "0.64.100.in-addr.arpa"
      end
    end

    describe "#ip" do
      it "should return the IP address of the networks bridge interface" do
        subject.ip.should == "100.64.0.254"
      end
    end

    describe "#cidr" do
      it "should return the CIDR of the networks bridge interface" do
        subject.cidr.should == 24
      end
    end

    describe "#netmask" do
      it "should return the netmask of the networks bridge interface" do
        subject.netmask.should == "255.255.255.0"
      end
    end

    describe "#network" do
      it "should return the network address of the networks bridge interface" do
        subject.network.should == "100.64.0.0"
      end
    end

    describe "#broadcast" do
      it "should return the broadcast address of the networks bridge interface" do
        subject.broadcast.should == "100.64.0.255"
      end
    end

    describe "#status" do
      it "should return a hash of status information about the container" do
        subject.stub(:state) { :stopped }
        subject.status.should be_kind_of(Hash)
        subject.status.should_not be_empty
      end
    end

    describe "#state" do
      it "should return the state of the bridge" do
        subject.node.stub(:dead?) { false }
        subject.node.ssh.stub(:exec) { OpenStruct.new(:output => "          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1") }
        subject.state.should == :running
      end
    end

    describe "#create" do
      it "should create the network bridge" do
        subject.node.stub(:alive?) { true }
        subject.node.stub(:state) { :running }
        subject.node.ssh.stub(:bootstrap) { true }

        subject.stub(:state) { :not_created }
        subject.stub(:provisioners) { Array.new }

        subject.create
      end
    end

    describe "#destroy" do
      it "should destroy the network bridge" do
        subject.node.stub(:alive?) { true }
        subject.node.stub(:state) { :running }
        subject.node.ssh.stub(:bootstrap) { true }

        subject.stub(:state) { :stopped }
        subject.stub(:provisioners) { Array.new }

        subject.destroy
      end
    end

    describe "#up" do
      it "should online the network bridge" do
        subject.node.stub(:alive?) { true }
        subject.node.stub(:state) { :running }
        subject.node.ssh.stub(:bootstrap) { true }

        subject.stub(:state) { :stopped }
        subject.stub(:provisioners) { Array.new }

        subject.up
      end
    end

    describe "#down" do
      it "should offline the network bridge" do
        subject.node.stub(:alive?) { true }
        subject.node.stub(:state) { :running }
        subject.node.ssh.stub(:bootstrap) { true }

        subject.stub(:state) { :running }
        subject.stub(:provisioners) { Array.new }

        subject.down
      end
    end

    describe "#provision" do
      it "should create and online the network" do
        subject.node.stub(:alive?) { true }
        subject.node.stub(:state) { :running }

        subject.stub(:state) { :running }
        subject.stub(:create) { true }
        subject.stub(:up) { true }
        subject.stub(:provisioners) { Array.new }

        subject.provision
      end
    end

    describe "#deprovision" do
      it "should create and online the network" do
        subject.node.stub(:alive?) { true }
        subject.node.stub(:state) { :running }

        subject.stub(:state) { :running }
        subject.stub(:down) { true }
        subject.stub(:destroy) { true }
        subject.stub(:provisioners) { Array.new }

        subject.deprovision
      end
    end

    describe "#build" do
      it "should build the network" do
        subject.stub(:create) { true }
        subject.stub(:up) { true }
        subject.stub(:provision) { true }

        subject.build.should == true
      end
    end

    describe "#demolish" do
      it "should demolish the network" do
        subject.stub(:destroy) { true }
        subject.stub(:down) { true }
        subject.stub(:deprovision) { true }

        subject.demolish.should == true
      end
    end

    describe "#recycle" do
      it "should recycle the network" do
        subject.stub(:demolish) { true }
        subject.stub(:build) { true }

        subject.recycle.should == true
      end
    end

    describe "#bounce" do
      it "should bounce the network" do
        subject.stub(:down) { true }
        subject.stub(:up) { true }

        subject.bounce.should == true
      end
    end

  end

end

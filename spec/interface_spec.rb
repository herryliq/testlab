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

describe TestLab::Interface do

  subject {
    @logger = ZTK::Logger.new('/tmp/test.log')
    @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new, :logger => @logger)
    @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
    @testlab.boot

    TestLab::Container.first('master').primary_interface
  }

  describe "class" do

    it "should be an instance of TestLab::Interface" do
      subject.should be_an_instance_of TestLab::Interface
    end

  end

  describe "methods" do

    describe "#ip" do
      it "should return the IP address of the interface" do
        subject.ip.should_not be_nil
        subject.ip.should_not be_empty
        subject.ip.should be_kind_of(String)
      end
    end

    describe "#netmask" do
      it "should return the netmask address of the interface" do
        subject.netmask.should_not be_nil
        subject.netmask.should_not be_empty
        subject.netmask.should be_kind_of(String)
      end
    end

    describe "#ptr" do
      it "should return the PTR address of the interface" do
        subject.ptr.should_not be_nil
        subject.ptr.should_not be_empty
        subject.ptr.should be_kind_of(String)
      end
    end

    describe "#cidr" do
      it "should return the CIDR mask of the interface" do
        subject.cidr.should_not be_nil
        subject.cidr.should be_kind_of(Integer)
      end
    end

    describe "#generate_ip" do
      it "should generate a random RFC compliant private IP address" do
        subject.generate_ip.should_not be_nil
        subject.generate_ip.should_not be_empty
        subject.generate_ip.should be_kind_of(String)
      end
    end

    describe "#generate_mac" do
      it "should generate a random RFC compliant private MAC address" do
        subject.generate_mac.should_not be_nil
        subject.generate_mac.should_not be_empty
        subject.generate_mac.should be_kind_of(String)
      end
    end

  end

end

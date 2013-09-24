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
require "gli"

describe TestLab::Utility::Logger do

  subject {
    TestLab::Utility::Logger
  }

  describe "class" do

    it "should be an instance of TestLab::Utility::Logger" do
      subject.should be TestLab::Utility::Logger
    end

  end

  describe "methods" do

    subject {
      @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
      @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
      @testlab.boot

      class A
        extend TestLab::Utility::Logger
      end
      A
    }

    describe "#log_config" do
      it "should return a hash of data when given a testlab instance" do
        subject.log_config(@testlab).should_not be_nil
        subject.log_config(@testlab).should_not be_empty
        subject.log_config(@testlab).should be_kind_of(Hash)
      end
    end

    describe "#log_details" do
      it "should return a hash of data when given a testlab instance" do
        subject.log_details(@testlab).should_not be_nil
        subject.log_details(@testlab).should_not be_empty
        subject.log_details(@testlab).should be_kind_of(Hash)
      end
    end

    describe "#log_ruby" do
      it "should return a hash of data when given a testlab instance" do
        subject.log_ruby(@testlab).should_not be_nil
        subject.log_ruby(@testlab).should_not be_empty
        subject.log_ruby(@testlab).should be_kind_of(Hash)
      end
    end

    describe "#log_gem_dependencies" do
      it "should return a hash of data when given a testlab instance" do
        subject.log_gem_dependencies(@testlab).should_not be_nil
        subject.log_gem_dependencies(@testlab).should_not be_empty
        subject.log_gem_dependencies(@testlab).should be_kind_of(Hash)
      end
    end

    describe "#log_external_dependencies" do
      it "should return a hash of data when given a testlab instance" do
        subject.log_external_dependencies(@testlab).should_not be_nil
        subject.log_external_dependencies(@testlab).should_not be_empty
        subject.log_external_dependencies(@testlab).should be_kind_of(Hash)
      end
    end

    describe "#log_header" do
      it "should return a hash of data when given a testlab instance" do
        subject.log_header(@testlab).should_not be_nil
        subject.log_header(@testlab).should_not be_empty
        subject.log_header(@testlab).should be_kind_of(Array)
      end
    end

  end

end

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

describe TestLab::Labfile do

  subject {
    @ui = ui_helper
    @testlab = testlab_helper(:ui => @ui)
    @testlab.boot
    @testlab.labfile
  }

  describe "class" do

    it "should be an instance of TestLab::Labfile" do
      subject.should be_an_instance_of TestLab::Labfile
    end

  end

  describe "methods" do

    describe "config_dir" do
      it "should return the configuration directory for the lab" do
        subject.config_dir.should be_kind_of(String)
        subject.config_dir.should_not be_empty
      end
    end

    describe "repo_dir" do
      it "should return the configuration directory for the lab" do
        subject.repo_dir.should be_kind_of(String)
        subject.repo_dir.should_not be_empty
      end
    end

  end

end

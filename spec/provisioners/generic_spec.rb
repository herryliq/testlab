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

include TestLab::Utility::Misc

[
  TestLab::Provisioner::Apt,
  TestLab::Provisioner::AptCacherNG,
  TestLab::Provisioner::Bind,
  TestLab::Provisioner::HostsFile,
  TestLab::Provisioner::NFSMount,
  TestLab::Provisioner::Raring,
  TestLab::Provisioner::Resolv,
  TestLab::Provisioner::Route,
  TestLab::Provisioner::Shell
].each do |klass|

  describe klass do

    subject {
      @ui = ZTK::UI.new(:stdout => StringIO.new, :stderr => StringIO.new)
      @testlab = TestLab.new(:repo_dir => REPO_DIR, :labfile_path => LABFILE_PATH, :ui => @ui)
      @testlab.boot
      TestLab::Container.first("server-#{klass.to_s.split('::').last.downcase}")
    }

    describe "class" do

      it "should be an instance of #{klass}" do
        subject.provisioners.last.new(subject.config, @ui).should be_an_instance_of klass
      end

    end

    describe "methods" do

      before(:each) do
        ZTK::SSH.any_instance.stub(:file).and_yield(StringIO.new)
        ZTK::SSH.any_instance.stub(:exec) { OpenStruct.new(:output => "", :exit_code => 0) }
        ZTK::SSH.any_instance.stub(:bootstrap) { "" }

        ZTK::Command.any_instance.stub(:exec) { OpenStruct.new(:output => "", :exit_code => 0) }
      end

      %w( create destroy up down provision deprovision import export ).each do |action|
        context action do

          it "should #{action} a node" do
            sym = "on_node_#{action}".to_sym
            p = klass.new(subject.config, @ui)
            p.respond_to?(sym) and p.send(sym, subject.node)
          end

          it "should #{action} a network" do
            sym = "on_network_#{action}".to_sym
            p = klass.new(subject.config, @ui)
            p.respond_to?(sym) and p.send(sym, subject.primary_interface.network)
          end

          it "should #{action} a container" do
            sym = "on_container_#{action}".to_sym
            p = klass.new(subject.config, @ui)
            p.respond_to?(sym) and p.send(sym, subject)
          end

        end
      end

    end

  end

end

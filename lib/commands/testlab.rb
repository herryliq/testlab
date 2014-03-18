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

# LAB BUILD
############
desc 'Build the lab (create->up->provision)'
long_desc <<-EOF
Attempts to build the defined lab.  TestLab will attempt to create, online and provision the lab components.

The components are built in the following order:

Nodes -> Networks -> Containers

TestLab will then attempt to build the components, executing the following tasks for each:

Create -> Up -> Provision
EOF
command :build do |build|
  build.desc %(Force the actions verbatium, do not attempt to infer shortcuts; this has no effect for most operations)
  build.switch [:f, :force]

  build.action do |global_options, options, args|
    @testlab.build(options[:force])
  end
end

# LAB DEMOLISH
###############
desc 'Demolish the lab (deprovision->down->destroy)'
long_desc <<-EOF
Attempts to demolish the defined lab.  TestLab will attempt to deprovision, offline and destroy the lab components.

The components are demolished in the following order:

Containers -> Networks -> Nodes

TestLab will then attempt to demolish the components, executing the following tasks for each:

Deprovision -> Down -> Destroy
EOF
command :demolish do |demolish|
  demolish.action do |global_options, options, args|
    @testlab.demolish
  end
end

# LAB BOUNCE
#############
desc 'Bounce the lab (down->up)'
long_desc <<-EOF
Attempts to bounce the lab.  TestLab will attempt to offline, then online the lab components.

The components are offlined in the following order:

Containers -> Networks -> Nodes

Then components are onlined in the following order:

Nodes -> Networks -> Containers
EOF
command :bounce do |bounce|
  bounce.action do |global_options, options, args|
    @testlab.bounce
  end
end

# LAB RECYCLE
##############
desc 'Recycle the lab (demolish->build)'
long_desc <<-EOF
Attempts to recycle the lab.  TestLab will attempt to demolish, then build the lab components.

The components are demolished in the following order:

Containers -> Networks -> Nodes

Then components are built in the following order:

Nodes -> Networks -> Containers
EOF
command :recycle do |recycle|
  recycle.desc %(Force the actions verbatium, do not attempt to infer shortcuts; this has no effect for most operations)
  recycle.switch [:f, :force]

  recycle.action do |global_options, options, args|
    @testlab.recycle(options[:force])
  end
end

# LAB CREATE
#############
desc 'Create the lab components'
long_desc <<-EOF
Attempts to create the defined lab components.

The components are created in the following order:

Nodes -> Networks -> Containers
EOF
command :create do |create|
  create.action do |global_options, options, args|
    @testlab.create
  end
end

# LAB DESTROY
##############
desc 'Destroy the lab components'
long_desc <<-EOF
Attempts to destroy the defined lab components.

The components are destroyed in the following order:

Nodes -> Networks -> Containers
EOF
command :destroy do |destroy|
  destroy.action do |global_options, options, args|
    @testlab.destroy
  end
end

# LAB ONLINE
#############
desc 'On-line the lab components'
long_desc <<-EOF
Attempts to online the defined lab components.

The components are onlined in the following order:

Nodes -> Networks -> Containers
EOF
command :up do |up|
  up.action do |global_options, options, rgs|
    @testlab.up
  end
end

# LAB OFFLINE
##############
desc 'Off-line the lab components'
long_desc <<-EOF
Attempts to offline the defined lab components.

The components are offlined in the following order:

Containers -> Networks -> Nodes
EOF
command :down do |down|
  down.action do |global_options, options, args|
    @testlab.down
  end
end

# LAB PROVISION
################
desc 'Provision the lab components'
long_desc <<-EOF
Attempts to provision the defined lab components.

The components are provisioned in the following order:

Nodes -> Networks -> Containers
EOF
command :provision do |provision|
  provision.action do |global_options, options, args|
    @testlab.provision
  end
end

# LAB DEPROVISION
##################
desc 'De-provision the lab components'
long_desc <<-EOF
Attempts to deprovision the defined lab components.

The components are torndown in the following order:

Containers -> Networks -> Nodes
EOF
command :deprovision do |deprovision|
  deprovision.action do |global_options, options, args|
    @testlab.deprovision
  end
end

# LAB STATUS
#############
desc 'Display the lab status'
command :status do |status|
  status.action do |global_options, options, args|
    @testlab.ui.logger.level = ZTK::Logger::WARN
    @testlab.ui.stdout.puts("\nNODES:".green.bold)
    commands[:node].commands[:status].execute({}, {}, [])

    @testlab.ui.stdout.puts("\nNETWORKS:".green.bold)
    commands[:network].commands[:status].execute({}, {}, [])

    @testlab.ui.stdout.puts("\nCONTAINERS:".green.bold)
    commands[:container].commands[:status].execute({}, {}, [])
  end
end

# LAB BUG REPORT
#################
desc 'Generate a bug report'
command :bugreport do |bugreport|
  bugreport.action do |global_options, options, args|

    def build_header(message)
      char    = '#'
      header  = "#{char * 30}   #{message}   #{char * 30}"
      content = Array.new

      content << (char * header.uncolor.length)
      content << header
      content << (char * header.uncolor.length)

      content
    end

    @testlab.ui.logger.level = ZTK::Logger::FATAL

    report_file = File.join("", "tmp", "testlab-bug-report.#{Time.now.utc.to_i}")

    content = Array.new
    content << (IO.read(DEFAULT_DUMP_FILE) rescue nil)

    content << build_header("TestLab Log")
    content << IO.read(DEFAULT_LOG_FILE)

    Dir[DEFAULT_LOG_GLOB].each do |log_filename|
      content << build_header("TestLab Log: #{log_filename.inspect}")
      content << IO.read(log_filename)
    end

    IO.write(report_file, content.flatten.compact.join("\n"))

    File.exists?(DEFAULT_LOG_FILE) and FileUtils.rm_f(DEFAULT_LOG_FILE)
    Dir[DEFAULT_LOG_GLOB].each do |log_filename|
      File.exists?(log_filename) and FileUtils.rm_f(log_filename)
    end

    @testlab.ui.stderr.puts("The bug report for your most recent execution of TestLab is located at #{report_file.inspect}.")
  end
end

# LAB DOCTOR
#############
desc 'Check the health of the lab'
long_desc <<-EOF
Attempts to analyze the health of the lab and report any issues.
EOF
command :doctor do |doctor|
  doctor.action do |global_options, options, args|
    if @testlab.doctor == true
      @testlab.ui.stdout.puts("Everything is OK".green.bold)
    else
      @testlab.ui.stdout.puts(format_message("OH NOES!  SOMETHING IS SCREWED UP!".red.bold))
    end
  end
end

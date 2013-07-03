class TestLab
  module Utility

    # GLI Module
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    module GLI
      require 'ztk'

      LAB_ACTION_ORDER = %W(create destroy up down setup teardown build demolish).map(&:to_sym)

      LAB_ACTIONS = {
        :create   => ["Construct %s",    "Attempts to create the <%= @component %>."],
        :destroy  => ["Destruct %s",     "Attempts to destroy the <%= @component %>."],
        :up       => ["On-line %s",      "Attempts to online the <%= @component %>."],
        :down     => ["Off-line %s",     "Attempts to offline the <%= @component %>."],
        :setup    => ["Provision %s",    "Attempts to provision the <%= @component %>."],
        :teardown => ["De-provision %s", "Attempts to deprovision the <%= @component %>."],
        :build    => ["Build %s", <<-EOF],
          Attempts to build the <%= @component %>.  TestLab will attempt to create, online and provision the <%= @component %>.

          The <%= @component %> are taken through the following states:

          Create -> Up -> Setup
          EOF
        :demolish => ["Demolish %s", <<-EOF]
          Attempts to demolish the <%= @component %>.  TestLab will attempt to deprovision, offline and destroy the <%= @component %>.

          The <%= @component %> are taken through the following states:

          Teardown -> Down -> Destroy
          EOF
      }

      def build_lab_commands(component, klass, &block)
        desc %(Manage lab #{component}s)
        command component do |c|
          c.desc %(Optional #{component} ID or comma separated list of #{component} IDs)
          c.arg_name %(#{component}[,#{component},...])
          c.flag [:n, :name]

          LAB_ACTION_ORDER.each do |lab_action|
            action_desc = LAB_ACTIONS[lab_action]
            c.desc(action_desc.first % "#{component}s")
            c.long_desc(ZTK::Template.string(action_desc.last, {:component => "#{component}s"}))

            c.command lab_action do |la|
              la.action do |global_options, options, args|
                iterate_objects_by_name(options[:name], klass) do |object|
                  object.send(lab_action)
                end
              end
            end
          end

          !block.nil? and block.call(c)
        end
      end

      def iterate_objects_by_name(name, klass, &block)
        objects = Array.new
        klass_name = klass.to_s.split('::').last.downcase

        if name.nil?
          objects = klass.all
        else
          names = name.split(',')
          objects = klass.find(names)
        end

        (objects.nil? || (objects.count == 0)) and raise TestLab::TestLabError, "We could not find any of the #{klass_name}s you supplied!"

        objects.each do |object|
          !block.nil? and block.call(object)
        end

        objects
      end

    end

  end
end
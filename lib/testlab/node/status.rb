class TestLab
  class Node

    module Status

      # Node Status
      #
      # @return [Hash] A hash detailing the status of the node.
      def status
        {
          :ok => self.ok?.inspect,
          :id => self.id,
          :instance_id => @provider.instance_id,
          :state => @provider.state,
          :user => @provider.user,
          :identity => @provider.identity,
          :ip => @provider.ip,
          :port => @provider.port,
          :provider => @provider.class,
          :provisioners => self.provisioners.map(&:to_s).collect{ |p| p.split('::').last }.join(',')
        }
      end

      def ok?
        self.alive? or return false

        result = true

        # make sure the node has some free space
        free_space_percent = (self.exec(%(df -P /), :ignore_exit_status => true).output.split("\n")[1].split[-2].to_i rescue nil)
        if free_space_percent.nil?
          @ui.stderr.puts(format_message("ERROR: We could not determine how much free space node #{self.id.inspect} has!".red.bold))
          result = false
        elsif (free_space_percent >= 90)
          @ui.stderr.puts(format_message("WARNING: Your TestLab node #{self.id.inspect} is using #{free_space_percent}% of its available disk space!".red.bold))
          result = false
        end

        my_container_names = self.containers.map(&:id)
        node_container_names = self.lxc.containers.map(&:name)

        unknown_container_names = (node_container_names - my_container_names)
        unknown_running_container_names = self.lxc.containers.select{ |c| (unknown_container_names.include?(c.name) && (c.state == :running)) }.map(&:name)

        if unknown_container_names.count > 0
          if unknown_running_container_names.count > 0
            @ui.stderr.puts(format_message("WARNING: You have *running* containers on your TestLab node #{self.id.inspect} which are not defined in your Labfile!".red.bold))
            @ui.stderr.puts(format_message(">>> You may need to manually stop the following containers: #{unknown_running_container_names.join(', ')}".red.bold))
            result = false
          end

          @ui.stderr.puts(format_message("WARNING: You have containers on your TestLab node #{self.id.inspect} which are not defined in your Labfile!".red.bold))
          @ui.stderr.puts(format_message(">>> You may need to manually remove the following containers: #{unknown_container_names.join(', ')}".red.bold))
        end

        result
      end

    end

  end
end

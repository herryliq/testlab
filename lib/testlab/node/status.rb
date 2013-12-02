class TestLab
  class Node

    module Status

      # Node Status
      #
      # @return [Hash] A hash detailing the status of the node.
      def status
        {
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

        result
      end

    end

  end
end

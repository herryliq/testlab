class TestLab
  class Node

    module SSH

      # Node SSH Connection
      #
      # @return [ZTK::SSH] Returns a new or cached ZTK::SSH object for the node.
      def ssh(options={})
        if (!defined?(@ssh) || @ssh.nil?)
          @ssh ||= ZTK::SSH.new({:ui => @ui, :timeout => 3600, :silence => true}.merge(options))
          @ssh.config do |c|
            c.host_name = @provider.ip
            c.port      = @provider.port
            c.user      = @provider.user
            c.keys      = [@provider.identity].flatten.compact
          end
        end
        @ssh
      end

      # Container SSH Connection
      #
      # @return [ZTK::SSH] Returns a new or cached ZTK::SSH object for the
      #   container.
      def container_ssh(container, options={})
        name = container.id
        @container_ssh ||= Hash.new
        if @container_ssh[name].nil?
          @container_ssh[name] ||= ZTK::SSH.new({:ui => @ui, :timeout => 3600, :silence => true}.merge(options))
          @container_ssh[name].config do |c|
            c.proxy_host_name = @provider.ip
            c.proxy_port      = @provider.port
            c.proxy_user      = @provider.user
            c.proxy_keys      = @provider.identity

            c.host_name       = container.ip

            c.user            = (options[:user]   || container.primary_user.username)
            c.password        = (options[:passwd] || container.primary_user.password)
            c.keys            = (options[:keys]   || [container.primary_user.identity, @provider.identity].flatten.compact)
          end
        end
        @container_ssh[name]
      end

      # Shutdown all SSH connections
      #
      # @return [Boolean] True if successful.
      def ssh_shutdown!
        @ssh.nil? or @ssh.close
        @ssh = nil

        @container_ssh.nil? or @container_ssh.each do |name, ssh|
          ssh.nil? or ssh.close
        end
        @container_ssh = nil

        true
      end

    end

  end
end

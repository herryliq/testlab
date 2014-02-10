class TestLab
  class Container

    module Status

      # Container IP
      #
      # Returns the IP of the container.
      #
      # @return [String] The containers IP address.
      def ip
        TestLab::Utility.ip(self.primary_interface.address)
      end

      # Container CIDR
      #
      # Returns the CIDR of the container.
      #
      # @return [Integer] The containers CIDR address.
      def cidr
        TestLab::Utility.cidr(self.primary_interface.address)
      end

      # Container BIND PTR Record
      #
      # Returns a BIND reverse-DNS PTR record.
      #
      # @return [String] The containers ARPA PTR record.
      def ptr
        TestLab::Utility.ptr(self.primary_interface.address)
      end

      # Container FQDN
      #
      # Returns the FQDN for the container.
      #
      # @return [String] The containers FQDN.
      def fqdn
        self.domain ||= self.node.domain

        [self.id, self.domain].join('.')
      end

      # Container Status
      #
      # Returns a hash of status information for the container.
      #
      # @return [Hash] A hash of status information for the container.
      def status
        interfaces = self.interfaces.collect do |interface|
          "#{interface.network_id}:#{interface.name}:#{interface.ip}/#{interface.cidr}"
        end.join(', ')

        {
          :id => self.id,
          :mode => self.mode,
          :fqdn => self.fqdn,
          :state => self.state,
          :memory_usage => "#{self.memory_usage}M",
          :cpu_time => "#{self.cpu_usage}s",
          :disk_usage => "#{self.disk_usage}MB",
          :distro => self.distro,
          :release => self.release,
          :interfaces => interfaces,
          :provisioners => self.provisioners.map(&:to_s).collect{ |p| p.split('::').last }.join(','),
          :node_id => self.node.id,
          :inherited => (self.inherit.nil? ? 'none' : self.inherit),
          :priority => self.priority
        }
      end

      # Container Memory Usage
      def memory_usage
        if self.node.dead?
          0
        else
          self.lxc.memory_usage / (1024 * 1024)
        end
      end

      # Container CPU Time
      def cpu_usage
        if self.node.dead?
          0
        else
          self.lxc.cpu_usage
        end
      end

      # Container Disk Usage
      def disk_usage
        if self.node.dead?
          0
        else
          self.lxc.disk_usage / (1024 * 1024)
        end
      end

      # Container State
      #
      # What state the container is in.
      #
      # @return [Symbol] A symbol indicating the state of the container.
      def state
        if self.node.dead?
          :unknown
        else
          self.lxc.state
        end
      end

      # Container Mode
      #
      # What mode the container is in.
      # @return [Symbol] A symbol indicating the mode of the container.
      def mode
        if self.node.dead?
          :unknown
        else
          if self.is_ephemeral?
            :ephemeral
          else
            :persistent
          end
        end
      end

      # Container Importable
      #
      # If the container has a non-nil sc_url value, we assume since we can
      # supposedly download a shipping container image for the container
      # that it is therefore importable.
      # @return [Boolean] True if the container has a non-nil sc_url attribute,
      #   False otherwise.
      def importable?
        !self.sc_url.nil?
      end

    end

  end
end

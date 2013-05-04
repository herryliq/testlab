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
          :ip => @provider.ip,
          :port => @provider.port,
          :provider => @provider.class,
          :con => self.containers.count,
          :net => self.networks.count
        }
      end

    end

  end
end

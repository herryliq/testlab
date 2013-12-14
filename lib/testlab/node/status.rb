class TestLab
  class Node

    module Status

      # Node Status
      #
      # @return [Hash] A hash detailing the status of the node.
      def status
        {
          :ok => self.doctor.inspect,
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

    end

  end
end

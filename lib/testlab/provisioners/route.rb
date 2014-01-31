class TestLab

  class Provisioner

    # Route Provisioner Error Class
    class RouteError < ProvisionerError; end

    # Route Provisioner Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class Route
      include TestLab::Utility::Misc

      def initialize(config={}, ui=nil)
        @config = (config || Hash.new)
        @ui     = (ui     || TestLab.ui)

        @config[:route] ||= Hash.new

        @ui.logger.debug { "config(#{@config.inspect})" }
      end

      # Route: Network Up
      def on_network_up(network)
        manage_route(:add, network)

        true
      end

      # Route: Network Down
      def on_network_down(network)
        manage_route(:del, network)

        true
      end

      # Route: Node Down
      def on_node_down(node)
        node.networks.each do |network|
          manage_route(:del, network)
        end

        true
      end

    private

      def manage_route(action, network)
        command = ZTK::Command.new(:ui => @ui, :silence => true, :ignore_exit_status => true)

        case RUBY_PLATFORM
        when /darwin/ then
          action = ((action == :del) ? :delete : :add)
          command.exec(%(#{sudo} route #{action} -net #{TestLab::Utility.network(network.address)} #{network.node.ip} #{TestLab::Utility.netmask(network.address)}))
        when /linux/ then
          command.exec(%(#{sudo} route #{action} -net #{TestLab::Utility.network(network.address)} netmask #{TestLab::Utility.netmask(network.address)} gw #{network.node.ip}))
        end
      end

    end

  end
end

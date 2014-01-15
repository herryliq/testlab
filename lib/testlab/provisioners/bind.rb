class TestLab

  class Provisioner

    # Bind Provisioner Error Class
    class BindError < ProvisionerError; end

    # Bind Provisioner Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class Bind

      def initialize(config={}, ui=nil)
        @config = (config || Hash.new)
        @ui     = (ui     || TestLab.ui)

        @config[:bind] ||= Hash.new
        @config[:bind][:domain]     ||= "tld.invalid"
        @config[:bind][:forwarders] ||= %w(8.8.8.8 8.8.4.4)

        @ui.logger.debug { "config(#{@config.inspect})" }
      end

      # Bind: Node Provision
      #
      # @param [TestLab::Node] node The node that is being provisioned.
      # @return [Boolean] True if successful.
      def on_node_provision(node)
        @ui.logger.debug { "BIND Provisioner: Node #{node.id}" }

        bind_provision(node)

        true
      end

      # Bind: Container Provision
      #
      # @param [TestLab::Container] container The container which just came online.
      # @return [Boolean] True if successful.
      def on_container_provision(container)
        @ui.logger.debug { "BIND Provisioner: Container #{container.id}" }

        # ensure we override the config hash with the nodes configuration
        @config = container.node.config
        bind_provision(container.node)

        true
      end
      alias :on_container_up :on_container_provision

      # Bind: Network Provision
      #
      # @param [TestLab::Network] network The network that is being onlined.
      # @return [Boolean] True if successful.
      def on_network_provision(network)
        @ui.logger.debug { "BIND Provisioner: Network #{network.id}" }

        bind_reload(network.node)

        true
      end
      alias :on_network_up :on_network_provision

      # Builds the main bind configuration sections
      def build_bind_main_partial(file)
        bind_conf_template = File.join(TestLab::Provisioner.template_dir, "bind", "bind.erb")

        file.puts(ZTK::Template.do_not_edit_notice(:message => "TestLab v#{TestLab::VERSION} BIND Configuration", :char => '//'))
        file.puts(ZTK::Template.render(bind_conf_template, @config))
      end

      def build_bind_records
        forward_records = Hash.new
        reverse_records = Hash.new

        TestLab::Container.all.each do |container|
          container.domain ||= @config[:bind][:domain]

          container.interfaces.each do |interface|
            forward_records[container.domain] ||= Array.new
            forward_records[container.domain] << %(#{container.id} IN A #{interface.ip})

            reverse_records[interface.network_id] ||= Array.new
            reverse_records[interface.network_id] << %(#{interface.ptr} IN PTR #{container.fqdn}.)
          end

        end
        { :forward => forward_records, :reverse => reverse_records }
      end

      # Builds the bind configuration sections for our zones
      def build_bind_zone_partial(node, file)
        bind_zone_template = File.join(TestLab::Provisioner.template_dir, "bind", 'bind-zone.erb')

        bind_records = build_bind_records
        forward_records = bind_records[:forward]
        reverse_records = bind_records[:reverse]

        TestLab::Network.all.each do |network|
          context = {
            :zone => network.arpa
          }

          file.puts
          file.puts(ZTK::Template.render(bind_zone_template, context))

          build_bind_db(node, network.arpa, reverse_records[network.id])
        end

        TestLab::Container.domains.each do |domain|
          context = {
            :zone => domain
          }

          file.puts
          file.puts(ZTK::Template.render(bind_zone_template, context))

          build_bind_db(node, domain, forward_records[domain])
        end
      end

      def build_bind_db(node, zone, records)
        bind_db_template = File.join(TestLab::Provisioner.template_dir, "bind", 'bind-db.erb')

        node.file(:target => %(/etc/bind/db.#{zone}), :chown => "bind:bind") do |file|
          file.puts(ZTK::Template.do_not_edit_notice(:message => "TestLab v#{TestLab::VERSION} BIND DB: #{zone}", :char => ';'))
          file.puts(ZTK::Template.render(bind_db_template, { :zone => zone, :records => records }))
        end
      end

      # Builds the BIND configuration
      def build_bind_conf(node)
        node.file(:target => %(/etc/bind/named.conf), :chown => "bind:bind") do |file|
          build_bind_main_partial(file)
          build_bind_zone_partial(node, file)
        end
      end

      def bind_install(node)
        node.bootstrap(<<-EOSHELL)
          export DEBIAN_FRONTEND="noninteractive"

          (dpkg --status bind9 &> /dev/null || apt-get -qy install bind9)
          rm -fv /etc/bind/{*.arpa,*.zone,*.conf*}
        EOSHELL
      end

      def bind_reload(node)
        node.bootstrap(<<-EOSHELL)
          chown -Rv bind:bind /etc/bind
          rndc reload
        EOSHELL
      end

      def bind_provision(node)
        bind_install(node)
        build_bind_conf(node)
        bind_reload(node)
      end

    end

  end
end

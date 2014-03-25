class TestLab

  class Provisioner

    # HostsFile Provisioner Error Class
    class HostsFileError < ProvisionerError; end

    # HostsFile Provisioner Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class HostsFile
      include TestLab::Utility::Misc

      def initialize(config={}, ui=nil)
        @config  = (config || Hash.new)
        @ui      = (ui     || TestLab.ui)
        @command = ZTK::Command.new(:ui => @ui, :silence => true, :ignore_exit_status => true)

        @ui.logger.debug { "config(#{@config.inspect})" }
      end

      # HostsFile: Container Provision
      def on_container_callback(container)
        remove_hosts(container)
        add_hosts(container)

        true
      end
      alias :on_container_create :on_container_callback
      alias :on_container_up :on_container_callback
      alias :on_container_provision :on_container_callback

      alias :on_container_deprovision:on_container_callback
      alias :on_container_down :on_container_callback
      alias :on_container_destroy :on_container_callback

    private

      def add_hosts(container)
        script = <<-EOF
cat <<EOI | #{sudo} tee -a /etc/hosts
#{hosts_blob(container)}
EOI
        EOF

        tempfile = Tempfile.new('script')
        tempfile.write(script)
        tempfile.flush

        command = %(/bin/bash -x #{tempfile.path})

        @command.exec(command)
        container.alive? and container.bootstrap(script)
      end

      def remove_hosts(container)
        @command.exec(sed_hostsfile)
        container.alive? and container.exec(sed_hostsfile('linux'))
      end

      def hosts_blob(container)
        blob = Array.new
        blob << def_tag
        container.node.containers.each do |con|
          blob << "#{con.primary_interface.ip}\t#{con.id} #{con.fqdn}"
        end
        blob << end_tag

        blob.join("\n")
      end

      def sed_hostsfile(platform=RUBY_PLATFORM)
        case platform
        when /darwin/ then
          %(#{sudo} sed -i '' '/#{def_tag}/,/#{end_tag}/d' /etc/hosts)
        when /linux/ then
          %(#{sudo} sed -i '/#{def_tag}/,/#{end_tag}/d' /etc/hosts)
        end
      end

      # NFS Exports Start Definition Tag
      def def_tag
        "#TESTLAB-HOSTSFILE"
      end

      # NFS Exports End Definition Tag
      def end_tag
        "#TESTLAB-HOSTSFILE"
      end

    end

  end
end

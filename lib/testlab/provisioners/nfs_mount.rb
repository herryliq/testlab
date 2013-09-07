class TestLab

  class Provisioner

    # NFSMount Provisioner Error Class
    class NFSMountError < ProvisionerError; end

    # NFSMount Provisioner Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class NFSMount
      require 'base64'
      require 'digest/sha1'

      include TestLab::Utility::Misc

      def initialize(config={}, ui=nil)
        @config  = (config || Hash.new)
        @ui      = (ui     || TestLab.ui)
        @command = ZTK::Command.new(:ui => @ui, :silence => true, :ignore_exit_status => true)

        @config[:nfs_mounts] ||= Array.new

        @ui.logger.debug { "config(#{@config.inspect})" }
      end

      # NFSMount: Container Provision
      def on_container_provision(container)
        container.exec(%(sudo dpkg --status nfs-common || sudo apt-get -y install nfs-common))

        add_nfs_mounts(container)
        container_mount(container)

        true
      end

      # NFSMount: Container Up
      def on_container_up(container)
        (container.exec(%(sudo dpkg --status nfs-common), :ignore_exit_status => true).exit_code == 0) or return false

        add_nfs_mounts(container)
        container_mount(container)

        true
      end

      def on_container_deprovision(container)
        remove_nfs_mounts(container)

        true
      end
      alias :on_container_down :on_container_deprovision
      alias :on_container_destroy :on_container_deprovision

    private

      def add_nfs_mounts(container)
        @command.exec(<<-EOF)
set -x
#{service_check}
grep '#{def_tag(container)}' /etc/exports && exit 0
cat <<EOI | #{sudo} tee -a /etc/exports
#{def_tag(container)}
#{mount_blob(container)}
#{end_tag(container)}
EOI
#{restart_service_command}
        EOF
      end

      def remove_nfs_mounts(container)
        @command.exec(<<-EOF)
set -x
#{sed_exports(container)}
        EOF
      end

      def mount_blob(container)
        mount_entries = Array.new
        @config[:nfs_mounts].each do |nfs_mount|
          mount_entries << case RUBY_PLATFORM
          when /darwin/ then
            %(#{nfs_mount[1]})
          when /linux/ then
            %(#{nfs_mount[1]} *(rw,sync,no_subtree_check))
          end
        end
        mount_entries.join("\n")
      end

      def sed_exports(container)
        case RUBY_PLATFORM
        when /darwin/ then
          %(#{sudo} sed -i '' '/#{def_tag(container)}/,/#{end_tag(container)}/d' /etc/exports)
        when /linux/ then
          %(#{sudo} sed -i '/#{def_tag(container)}/,/#{end_tag(container)}/d' /etc/exports)
        end
      end

      def container_mount(container)
        @config[:nfs_mounts].each do |nfs_mount|
          container.exec(%(sudo mkdir -p #{nfs_mount[2]}))
          container.exec(%(sudo mount -vt nfs -o 'nfsvers=3' #{nfs_mount[0]}:#{nfs_mount[1]} #{nfs_mount[2]}), :ignore_exit_status => true)
        end
      end

      def restart_service_command
        case RUBY_PLATFORM
        when /darwin/ then
          %(#{sudo} nfsd restart ; sleep 10)
        when /linux/ then
          %(#{sudo} service nfs-kernel-server reload || #{sudo} service nfs-kernel-server restart)
        end
      end

      def service_check
        case RUBY_PLATFORM
        when /darwin/ then
          %(#{sudo} nfsd enable)
        when /linux/ then
          %((#{sudo} dpkg --status nfs-kernel-server || #{sudo} apt-get -y install nfs-kernel-server) && #{sudo} service nfs-kernel-server start)
        end
      end

      # NFS Exports Start Definition Tag
      def def_tag(container)
        "#TESTLAB-NFS-EXPORTS-DEF-#{container.id.to_s.upcase}"
      end

      # NFS Exports End Definition Tag
      def end_tag(container)
        "#TESTLAB-NFS-EXPORTS-END-#{container.id.to_s.upcase}"
      end

    end

  end
end

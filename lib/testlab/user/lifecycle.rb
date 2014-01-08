class TestLab
  class User

    module Lifecycle

      # Provision the user
      #
      # @return [Boolean] True if successful.
      def provision
        @ui.logger.debug { "User Create: #{self.username} " }

        node_home_dir = home_dir(self.container.node.user)
        node_authkeys = File.join(node_home_dir, ".ssh", "authorized_keys")

        # ensure the container user exists
        container_passwd_file = File.join(self.container.fs_root, "etc", "passwd")
        if self.container.node.exec(%(sudo grep "#{self.username}" #{container_passwd_file}), :ignore_exit_status => true).exit_code != 0

          if !self.gid.nil?
            groupadd_command = %(groupadd --gid #{self.gid} #{self.username})
            self.container.node.exec(%(sudo chroot #{self.container.fs_root} /bin/bash -c '#{groupadd_command}'))
          end

          useradd_command = %W(useradd --create-home --shell /bin/bash --groups sudo)
          useradd_command << "--uid #{self.uid}" if !self.uid.nil?
          useradd_command << "--gid #{self.gid}" if !self.gid.nil?
          useradd_command << self.username
          useradd_command = useradd_command.flatten.compact.join(' ')

          self.container.lxc.attach(%(-- /bin/bash -c '#{useradd_command}'))
          self.container.lxc.attach(%(-- /bin/bash -c 'echo "#{self.username}:#{self.password}" | chpasswd'))
        end

        # ensure the user user gets our node user key
        user_home_dir = File.join(self.container.fs_root, self.home_dir)
        user_authkeys = File.join(user_home_dir, ".ssh", "authorized_keys")
        user_authkeys2 = File.join(user_home_dir, ".ssh", "authorized_keys2")

        authkeys = {
          user_authkeys  => node_authkeys,
          user_authkeys2 => node_authkeys
        }

        public_identities = Array.new
        !self.public_identity.nil? and [self.public_identity].flatten.compact.each do |pi|
          if File.exists?(pi)
            public_identities << ::IO.read(pi).strip
          end
        end

        if (public_identities.count > 0)
          id_rsa_pub = File.join(user_home_dir, ".ssh", "id_rsa.pub")
          self.container.node.exec(%(sudo grep -e "#{public_identities.first}" #{id_rsa_pub} || echo "#{public_identities.first}" | sudo tee #{id_rsa_pub}), :ignore_exit_status => true)
          self.container.node.exec(%(sudo chmod -v 644 #{id_rsa_pub}), :ignore_exit_status => true)
        end

        authkeys.each do |destination, source|
          @ui.logger.info { "SOURCE: #{source} >>> #{destination}" }
          self.container.node.exec(%(sudo mkdir -pv #{File.dirname(destination)}))

          self.container.node.exec(%(sudo grep "$(cat #{source})" #{destination} || sudo cat #{source} | sudo tee -a #{destination}))

          public_identities.each do |pi|
            self.container.node.exec(%(sudo grep "#{pi}" #{destination} || sudo echo "#{pi}" | sudo tee -a #{destination}))
          end

          self.container.node.exec(%(sudo chmod -v 644 #{destination}))
        end

        identities = Array.new
        !self.identity.nil? and [self.identity].flatten.compact.each do |i|
          if File.exists?(i)
            identities << ::IO.read(i).strip
          end
        end

        if (identities.count > 0)
          id_rsa = File.join(user_home_dir, ".ssh", "id_rsa")
          self.container.node.exec(%(sudo grep -e "#{identities.first}" #{id_rsa} || echo "#{identities.first}" | sudo tee #{id_rsa}), :ignore_exit_status => true)
          self.container.node.exec(%(sudo chmod -v 400 #{id_rsa}), :ignore_exit_status => true)
        end

        # ensure the container user home directory is owned by them
        home_dir = self.container.lxc.attach(%(-- /bin/bash -c 'grep #{self.username} /etc/passwd | cut -d ":" -f6')).strip
        self.container.lxc.attach(%(-- /bin/bash -c 'sudo chown -R $(id -u #{self.username}):$(id -g #{self.username}) #{home_dir}'))

        # ensure the sudo user group can do passwordless sudo
        self.container.lxc.attach(%(-- /bin/bash -c 'grep "sudo\tALL=\(ALL:ALL\) ALL" /etc/sudoers && sed -i "s/sudo\tALL=\(ALL:ALL\) ALL/sudo\tALL=\(ALL:ALL\) NOPASSWD: ALL/" /etc/sudoers'))

        true
      end

      # User Home Directory
      #
      # Returns the path to the users home directory.
      #
      # @return [String] The users home directory.
      def home_dir(name=nil)
        username = (name || self.username)
        if (username == "root")
          "/root"
        else
          "/home/#{username}"
        end
      end

    end

  end
end

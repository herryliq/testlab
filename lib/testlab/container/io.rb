class TestLab
  class Container

    module IO
      require 'net/http'
      require 'net/https' if RUBY_VERSION < '1.9'
      require 'tempfile'

      PBZIP2_MEMORY    = 1024
      READ_SIZE        = ((64 * 1024) - 1)
      TRANSFER_MESSAGE = "transferring '%s' at %0.2fMB/s -- %0.2fMB of %0.2fMB -- %d%% (%01d:%02dT-%01d:%02d)   \r"

      def transfer_message(filename, current_size, total_size, elapsed)
        total_size_mb   = (total_size.to_f / (1024 * 1024).to_f)
        current_size_mb = (current_size.to_f / (1024 * 1024).to_f)

        speed    = (current_size.to_f / elapsed.to_f)
        speed    = total_size.to_f if (speed == 0.0)
        speed_mb = speed.to_f / (1024 * 1024).to_f

        minutes = elapsed.div(60)
        seconds = elapsed.modulo(60)

        estimated   = ((total_size.to_f - current_size.to_f) / speed.to_f)
        est_minutes = estimated.div(60)
        est_seconds = estimated.modulo(60)

        percentage_done = ((current_size * 100) / total_size)

        @ui.stdout.print(format_message(TRANSFER_MESSAGE.yellow % [File.basename(filename), speed_mb, current_size_mb, total_size_mb, percentage_done, minutes, seconds, est_minutes, est_seconds]))
      end

      def progress_callback(action, args)
        @total_size ||= 0

        case action
        when :open then
          @start_time = Time.now
          if (@total_size == 0)
            @total_size = args[0].size
          end

        when :get, :put then
          elapsed      = (Time.now - @start_time)
          current_size = (args[1] + args[2].length)

          transfer_message(args[0].local, current_size, @total_size, elapsed)

        when :finish
          @ui.stdout.puts
          @total_size = 0

        end
      end

      # Export the container
      #
      # @return [Boolean] True if successful.
      def export(compression=9, local_file=nil)
        @ui.logger.debug { "Container Export: #{self.id} " }

        self.node.alive? or return false
        self.node.ok?

        (self.state == :not_created) and raise ContainerError, 'You must create a container before you can export it!'

        # Throw an exception if we are attempting to export a container in a
        # ephemeral state.
        self.lxc_clone.exists? and raise ContainerError, 'You can not export ephemeral containers!'

        # Run our callbacks
        do_provisioner_callbacks(self, :export, @ui)

        # Ensure the container is stopped before we attempt to export it.
        self.down

        export_tempfile = Tempfile.new('export')
        remote_filename = File.basename(export_tempfile.path.dup)
        export_tempfile.close!

        remote_file  = File.join("", "tmp", remote_filename)
        local_file ||= File.join(Dir.pwd, "#{self.id}.sc")
        local_file   = File.expand_path(local_file)
        root_fs_path = self.lxc.fs_root.split(File::SEPARATOR).last

        please_wait(:ui => @ui, :message => format_object_action(self, 'Compress', :cyan)) do
          self.node.bootstrap(<<-EOF)
set -x
set -e

du -sh #{self.lxc.container_root}

cd #{self.lxc.container_root}
find #{root_fs_path} -depth -print0 | cpio -o0 | pbzip2 -#{compression} -vfczm#{PBZIP2_MEMORY} > #{remote_file}
chown ${SUDO_USER}:${SUDO_USER} #{remote_file}

ls -lah #{remote_file}
EOF
        end

        File.exists?(local_file) and FileUtils.rm_f(local_file)

        @total_size = self.node.ssh.sftp.stat!(remote_file).size

        self.node.download(remote_file, local_file, :on_progress => method(:progress_callback), :read_size => READ_SIZE)

        self.node.bootstrap(<<-EOF)
set -x
set -e

rm -fv #{remote_file}
EOF

        @ui.stdout.puts(format_message("Your shipping container is now exported and available at '#{local_file}'!".green.bold))

        true
      end

      # Import the container
      #
      # @return [Boolean] True if successful.
      def import(local_file)
        @ui.logger.debug { "Container Import: #{self.id}" }

        self.node.alive? or return false
        self.node.ok?

        import_tempfile = Tempfile.new('import')
        remote_filename = File.basename(import_tempfile.path.dup)
        import_tempfile.close!

        remote_file  = File.join("", "tmp", remote_filename)
        local_file ||= File.join(Dir.pwd, "#{self.id}.sc")
        local_file   = File.expand_path(local_file)
        root_fs_path = self.lxc.fs_root.split(File::SEPARATOR).last

        @ui.logger.debug { "Local File: #{local_file.inspect}" }

        if !File.exists?(local_file)
          self.sc_url.nil? and raise ContainerError, "You failed to supply a filename or URL to import from!"

          @ui.stdout.puts(format_message("Downloading shipping container for #{self.id}...".green.bold))

          sc_download(local_file, self.sc_url, 16)
        end

        # Ensure we are not in ephemeral mode.
        self.persistent

        self.down
        self.destroy

        self.create

        self.node.exec(%(sudo rm -fv #{remote_file}), :silence => true, :ignore_exit_status => true)
        self.node.upload(local_file, remote_file, :on_progress => method(:progress_callback), :read_size => READ_SIZE)

        please_wait(:ui => @ui, :message => format_object_action(self, 'Expand', :cyan)) do
          self.node.bootstrap(<<-EOF)
set -x
set -e

ls -lah #{remote_file}

rm -rf #{self.lxc.fs_root}
cd #{self.lxc.container_root}
pbzip2 -vdcm#{PBZIP2_MEMORY} #{remote_file} | cpio -uid && rm -fv #{remote_file}

du -sh #{self.lxc.container_root}

rm -fv #{remote_file}
EOF
        end

        self.up

        # Run our callbacks
        please_wait(:ui => @ui, :message => format_object_action(self, 'import', :cyan)) do
          do_provisioner_callbacks(self, :import, @ui)
        end

        @ui.stdout.puts(format_message("Your shipping container is now imported and available for use!".green.bold))

        true
      end

      # Copy the container
      #
      # Duplicates this container under another container definition.
      #
      # @return [Boolean] True if successful.
      def copy(target_name)
        @ui.logger.debug { "Container Copy: #{self.id}" }

        target_name.nil? and raise ContainerError, "You must supply a destination container!"

        target_container = self.node.containers.select{ |c| c.id.to_sym == target_name.to_sym }.first
        target_container.nil? and raise ContainerError, "We could not locate the target container!"

        source_state = self.state
        target_state = target_container.state

        target_container.demolish
        target_container.create

        self.down
        please_wait(:ui => @ui, :message => format_object_action(self, 'Copy', :yellow)) do
          self.node.exec(%(sudo rm -rf #{target_container.lxc.fs_root}))
          self.node.exec(%(sudo rsync -a #{self.lxc.fs_root} #{target_container.lxc.container_root}))
          self.node.exec(%(sudo rm -fv #{File.join(self.lxc.fs_root, '.*provision')}))
        end

        # bring the source container back online if it was running before the copy operation
        (source_state == :running) and self.up

        # bring the target container back online if it was running before the copy operation
        (target_state == :running) and target_container.up

        true
      end

      # Downloads a given shipping container image
      #
      # @return [Boolean] True if successful.
      def sc_download(local_file, url, count)
        (count <= 0) and raise ContainerError, "Too many redirects, aborting!"

        uri        = URI(url)
        http       = Net::HTTP.new(uri.host, uri.port)

        if (uri.scheme.downcase == 'https')
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE  # lets be really permissive for now
        end

        http.request_get(uri.path) do |response|
          case response
          when Net::HTTPNotFound then
            raise ContainerError, "The supplied sc_url for this container was 404 Not Found!"

          when Net::HTTPClientError then
            raise ContainerError, "Client Error: #{response.inspect}"

          when Net::HTTPRedirection then
            location = response['location']
            @ui.stdout.puts(format_message("REDIRECT: #{url} --> #{location}".white))
            return sc_download(local_file, location, (count - 1))

          when Net::HTTPOK then
            tempfile = Tempfile.new(%(download-#{self.id}))
            tempfile.binmode

            current_size = 0
            total_size   = response['content-length'].to_i
            start_time   = Time.now

            response.read_body do |chunk|
              tempfile << chunk

              elapsed  = (Time.now - start_time)
              current_size += chunk.size

              transfer_message(local_file, current_size, total_size, elapsed)
            end
            @ui.stdout.puts

            tempfile.close

            FileUtils.mkdir_p(File.dirname(local_file))
            File.exists?(local_file) and File.unlink(local_file)
            FileUtils.mv(tempfile.path, local_file, :force => true)

            true
          else
            raise ContainerError, "Unknown HTTP response when attempt to download your shipping container!"
          end
        end

      end

    end

  end
end

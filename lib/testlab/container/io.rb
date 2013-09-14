class TestLab
  class Container

    module IO
      require 'net/http'
      require 'net/https' if RUBY_VERSION < '1.9'
      require 'tempfile'

      PBZIP2_MEMORY = 256

      # Export the container
      #
      # @return [Boolean] True if successful.
      def export(compression=9, local_file=nil)
        @ui.logger.debug { "Container Export: #{self.id} " }

        (self.state == :not_created) and raise ContainerError, 'You must create a container before you can export it!'

        # Throw an exception if we are attempting to export a container in a
        # ephemeral state.
        self.lxc_clone.exists? and raise ContainerError, 'You can not export ephemeral containers!'

        # Ensure the container is stopped before we attempt to export it.
        self.down

        export_tempfile = Tempfile.new('export')
        remote_filename = File.basename(export_tempfile.path.dup)
        export_tempfile.close!

        remote_file  = File.join("", "tmp", remote_filename)
        local_file ||= File.join(Dir.pwd, File.basename(remote_file))
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

        please_wait(:ui => @ui, :message => format_object_action(self, 'Export', :cyan)) do
          File.exists?(local_file) and FileUtils.rm_f(local_file)
          self.node.download(remote_file, local_file)
        end

        @ui.stdout.puts(format_message("Your shipping container is now exported and available at '#{local_file}'!".green.bold))

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
            puts(format_message("REDIRECTED  #{url} --> #{location}".black))
            return sc_download(local_file, location, (count - 1))

          when Net::HTTPOK then
            tempfile = Tempfile.new(%(download-#{self.id}))
            tempfile.binmode

            current_size = 0
            progress = 0
            total_size = response['content-length'].to_i
            total_size_mb = total_size.to_f / (1024 * 1024).to_f

            start_time = Time.now
            response.read_body do |chunk|
              tempfile << chunk

              current_size += chunk.size
              current_size_mb = current_size.to_f / (1024 * 1024).to_f

              new_progress = (current_size * 100) / total_size
              unless new_progress == progress
                elapsed = (Time.now - start_time)
                speed_mb = (current_size.to_f / elapsed.to_f) / (1024 * 1024).to_f
                print(format_message("Downloading %s - %0.2fMB of %0.2fMB [%0.2fMB/s] (%d%%)\r".green.bold % [local_file, current_size_mb, total_size_mb, speed_mb, new_progress]))
              end
              progress = new_progress
            end

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

      # Import the container
      #
      # @return [Boolean] True if successful.
      def import(local_file)
        @ui.logger.debug { "Container Import: #{self.id} " }

        if !File.exists?(local_file)
          self.sc_url.nil? and raise ContainerError, "You failed to supply a filename or URL to import from!"

          puts(format_message("Downloading shipping container for #{self.id}...".green.bold))

          local_file = File.expand_path("#{self.id}.sc")
          sc_download(local_file, self.sc_url, 16)
        end

        halt!

        # Ensure we are not in ephemeral mode.
        self.persistent

        self.down
        self.destroy
        self.create

        import_tempfile = Tempfile.new('import')
        remote_filename = File.basename(import_tempfile.path.dup)
        import_tempfile.close!

        remote_file  = File.join("", "tmp", remote_filename)
        local_file   = File.expand_path(local_file)
        root_fs_path = self.lxc.fs_root.split(File::SEPARATOR).last

        please_wait(:ui => @ui, :message => format_object_action(self, 'Import', :cyan)) do
          self.node.exec(%(sudo rm -fv #{remote_file}), :silence => true, :ignore_exit_status => true)
          self.node.upload(local_file, remote_file)
        end

        please_wait(:ui => @ui, :message => format_object_action(self, 'Expand', :cyan)) do
          self.node.bootstrap(<<-EOF)
set -x
set -e

ls -lah #{remote_file}

rm -rf #{self.lxc.fs_root}
cd #{self.lxc.container_root}
pbzip2 -vdcm#{PBZIP2_MEMORY} #{remote_file} | cpio -uid && rm -fv #{remote_file}

du -sh #{self.lxc.container_root}
EOF
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

    end

  end
end

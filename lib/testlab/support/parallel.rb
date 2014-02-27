class TestLab
  module Support

    module Parallel

      # Perform actions against a collection of objects in parallel.
      #
      # @return [Boolean] True if successful.
      def do_parallel_actions(klass, objects, action, reverse=false, &block)

        # Our before fork hook; we should reset our SSH connections before
        # forking, they will automatically re-establish after forking.
        def before_fork(pid)
          defined?(nodes) and nodes.each do |node|
            node.ssh_shutdown!
          end
        end

        # Clear the screen and move the cursor to x:0, y:0 using ANSI escape
        # codes
        #
        # @return [Boolean] Returns True if successful.
        def reset_screen
          self.ui.stdout.puts(ZTK::ANSI.reset)
          self.ui.stdout.puts(ZTK::ANSI.goto(0, 0))

          true
        end

        klass_name = klass.to_s.split('::').last
        command    = ZTK::Command.new(:silence => true, :ignore_exit_status => true)
        parallel   = ZTK::Parallel.new(:ui => self.ui)
        parallel.config do |config|
          config.before_fork = method(:before_fork)
        end

        priority_groups = klass.priority_groups
        (reverse == true) and priority_groups.reverse!

        priority_groups.each do |priority_group|

          selected_objects = objects.select{ |c| c.priority == priority_group }
          if selected_objects.count == 1
            object = selected_objects.first

            block.call(object, action, klass)
          else
            selected_objects.each do |object|
              parallel.process do
                $0 = "TestLab #{klass_name.capitalize} #{action.to_s.capitalize}: #{object.id.inspect}"

                # Redirect all standard I/O to /dev/null
                self.ui.stdout.reopen("/dev/null", "a")
                self.ui.stderr.reopen("/dev/null", "a")
                self.ui.stdin.reopen("/dev/null")

                # Redirect logging to an object specific log file
                log_filename = "/tmp/testlab.log.#{object.id.to_s.downcase}"
                File.exists?(log_filename) && FileUtils.rm_f(log_filename)
                self.ui.logger = ZTK::Logger.new(log_filename)

                block.call(object, action, klass)
              end
            end

            while (parallel.count > 0) do
              message = format_message("Parallel #{action.to_s.capitalize} Running:".yellow)

              reset_screen
              self.ui.stdout.puts(message)
              self.ui.stdout.puts("-" * message.uncolor.length)
              self.ui.stdout.print(command.exec(%(ps u --pid #{parallel.pids.join(' ')} 2>/dev/null)).output)

              sleep(1)

              # Attempt to reap processes faster, otherwise we'll only reap one
              # per second if we're lucky.
              for x in 1..(parallel.count) do
                parallel.wait(Process::WNOHANG)
              end
            end

            reset_screen
          end
        end

        true
      end

    end

  end
end

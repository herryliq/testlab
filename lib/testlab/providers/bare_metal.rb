class TestLab

  class Provider

    # BareMetal Provider Error Class
    class BareMetalError < ProviderError; end

    # BareMetal Provider Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class BareMetal

      def initialize(config={}, ui=nil)
        @config = (config || Hash.new)
        @ui     = (ui     || TestLab.ui)

        # ensure our bare_metal key exists
        @config[:bare_metal] ||= Hash.new
      end

      # This is a NO-OP
      def create
        true
      end

      # This is a NO-OP
      def destroy
        true
      end

      # This is a NO-OP
      def up
        true
      end

      # This is a NO-OP
      def down
        true
      end

      # This is a NO-OP
      def reload
        self.down
        self.up

        true
      end

      # This is a NO-OP
      def state
        :running
      end

      # This is a NO-OP
      def exists?
        true
      end

      # This is a NO-OP
      def alive?
        true
      end

      # This is a NO-OP
      def dead?
        false
      end

      def instance_id
        TestLab.hostname
      end

      def user
        (@config[:bare_metal][:user] || ENV['USER'])
      end

      def identity
        (@config[:bare_metal][:identity] || File.join(ENV['HOME'], ".ssh", "id_rsa"))
      end

      def ip
        (@config[:bare_metal][:ip] || "127.0.0.1")
      end

      def port
        (@config[:bare_metal][:port] || 22)
      end

    end

  end
end

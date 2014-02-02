class TestLab
  module Support

    module Lifecycle

      # Build the object
      def build(force=false)
        if (force == false) and self.respond_to?(:importable?) and self.respond_to?(:import) and (self.importable? == true)
          import
        else
          create
          up
          provision
        end

        true
      end

      # Demolish the object
      def demolish
        deprovision
        down
        destroy

        true
      end

      # Recycle the object
      def recycle(force=false)
        demolish
        build(force)

        true
      end

      # Bounce the object
      def bounce
        down
        up

        true
      end

    end

  end
end

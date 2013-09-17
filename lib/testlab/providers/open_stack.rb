class TestLab

  class Provider

    # OpenStack Provider Error Class
    class OpenStackError < ProviderError; end

    # OpenStack Provider Class
    #
    # @author Zachary Patten <zachary AT jovelabs DOT com>
    class OpenStack

      def initialize(ui=ZTK::UI.new)
        @ui = ui
      end

    end

  end
end

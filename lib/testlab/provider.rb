class TestLab

  # Provider Error Class
  class ProviderError < TestLabError; end

  # Provider Class
  #
  # @author Zachary Patten <zachary AT jovelabs DOT com>
  class Provider
    PROXY_METHODS = %w(instance_id state user identity ip port create destroy up down export import reload status alive? dead? exists?).map(&:to_sym)

    autoload :AWS,       'testlab/providers/aws'
    autoload :BareMetal, 'testlab/providers/bare_metal'
    autoload :Local,     'testlab/providers/local'
    autoload :OpenStack, 'testlab/providers/open_stack'
    autoload :Vagrant,   'testlab/providers/vagrant'

    class << self

      # Returns the path to the gems provider templates
      def template_dir
        File.join(TestLab.gem_dir, "lib", "testlab", "providers", "templates")
      end

    end

  end

end

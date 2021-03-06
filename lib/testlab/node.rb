class TestLab

  # Node Error Class
  class NodeError < TestLabError; end

  # Node Class
  #
  # @author Zachary Patten <zachary AT jovelabs DOT com>
  class Node < ZTK::DSL::Base
    STATUS_KEYS   = %w(id instance_id ok state user ip port provider provisioners).map(&:to_sym)

    # Sub-Modules
    autoload :Actions,       'testlab/node/actions'
    autoload :ClassMethods,  'testlab/node/class_methods'
    autoload :Doctor,        'testlab/node/doctor'
    autoload :LXC,           'testlab/node/lxc'
    autoload :MethodMissing, 'testlab/node/method_missing'
    autoload :Provision,     'testlab/node/provision'
    autoload :SSH,           'testlab/node/ssh'
    autoload :Status,        'testlab/node/status'

    include TestLab::Node::Actions
    include TestLab::Node::Doctor
    include TestLab::Node::LXC
    include TestLab::Node::MethodMissing
    include TestLab::Node::Provision
    include TestLab::Node::SSH
    include TestLab::Node::Status

    extend  TestLab::Node::ClassMethods

    include TestLab::Support::Execution
    include TestLab::Support::Lifecycle

    include TestLab::Utility::Misc

    # Associations and Attributes
    belongs_to :labfile,       :class_name => 'TestLab::Labfile'

    has_many   :containers,    :class_name => 'TestLab::Container'
    has_many   :networks,      :class_name => 'TestLab::Network'

    attribute  :provider
    attribute  :provisioners,  :default => Array.new
    attribute  :config,        :default => Hash.new

    # Execution priority; set the order in which the object should execute when
    # performing parallel operations; a higher value priority equates to more
    # precedence.  Objects with identical priority values will execute in
    # parallel.
    attribute   :priority,       :default => 0


    def initialize(*args)
      @ui = TestLab.ui

      @ui.logger.debug { "Loading Node" }

      super(*args)

      self.config.merge!(:node => { :id => self.id.dup })

      @provider = self.provider.new(self.config, @ui)

      raise NodeError, "You must specify a provider class!" if self.provider.nil?

      @ui.logger.debug { "Node '#{self.id}' Loaded" }
    end

    def config_dir
      self.labfile.config_dir
    end

    def repo_dir
      self.labfile.repo_dir
    end

    def domain
      self.config[:bind] ||= Hash.new
      self.config[:bind][:domain] ||= 'tld.invalid'
    end

    class << self

      def priority_groups
        self.all.map(&:priority).sort.uniq.reverse
      end

      def by_priority(priority)
        self.all.select{ |n| n.priority == priority }
      end

    end

  end

end

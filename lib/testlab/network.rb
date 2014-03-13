class TestLab

  # Network Error Class
  class NetworkError < TestLabError; end

  # Network Class
  #
  # @author Zachary Patten <zachary AT jovelabs DOT com>
  class Network < ZTK::DSL::Base
    STATUS_KEYS   = %w(id node_id state interface network netmask broadcast provisioners).map(&:to_sym)

    # Sub-Modules
    autoload :Actions,      'testlab/network/actions'
    autoload :Bind,         'testlab/network/bind'
    autoload :ClassMethods, 'testlab/network/class_methods'
    autoload :Provision,    'testlab/network/provision'
    autoload :Status,       'testlab/network/status'

    include TestLab::Network::Actions
    include TestLab::Network::Bind
    include TestLab::Network::Provision
    include TestLab::Network::Status

    extend  TestLab::Network::ClassMethods

    include TestLab::Support::Lifecycle

    include TestLab::Utility::Misc

    # Associations and Attributes
    belongs_to  :node,          :class_name => 'TestLab::Node'
    has_many    :interfaces,    :class_name => 'TestLab::Interface'

    attribute   :provisioners,  :default => Array.new
    attribute   :config,        :default => Hash.new

    attribute   :address
    attribute   :bridge

    # Execution priority; set the order in which the object should execute when
    # performing parallel operations; a higher value priority equates to more
    # precedence.  Objects with identical priority values will execute in
    # parallel.
    attribute   :priority,       :default => 0


    def initialize(*args)
      @ui = TestLab.ui

      @ui.logger.debug { "Loading Network" }
      super(*args)
      @ui.logger.debug { "Network '#{self.id}' Loaded" }
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

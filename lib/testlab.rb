require 'ztk'

require 'testlab/version'
require 'testlab/monkeys'

# Top-Level TestLab Class
#
# @author Zachary Patten <zachary@jovelabs.net>
class TestLab

  # Top-Level Error Class
  class TestLabError < StandardError; end

  # Main Classes
  autoload :Container,   'testlab/container'
  autoload :Interface,   'testlab/interface'
  autoload :Labfile,     'testlab/labfile'
  autoload :Network,     'testlab/network'
  autoload :Node,        'testlab/node'
  autoload :Provider,    'testlab/provider'
  autoload :Provisioner, 'testlab/provisioner'
  autoload :Utility,     'testlab/utility'

  include TestLab::Utility::Misc

  @@ui ||= nil

  def initialize(options={})
    labfile      = (options[:labfile] || 'Labfile')
    labfile_path = ZTK::Locator.find(labfile)

    @@ui         = (options[:ui] || ZTK::UI.new)

    @labfile     = TestLab::Labfile.load(labfile_path)
  end

  # Test Lab Nodes
  #
  # Returns an array of our defined nodes.
  #
  # @return [Array<TestLab::Node>] An array of all defined nodes.
  def nodes
    TestLab::Node.all
  end

  # Test Lab Containers
  #
  # Returns an array of our defined containers.
  #
  # @return [Array<TestLab::Container>] An array of all defined containers.
  def containers
    TestLab::Container.all
  end

  # Test Lab Networks
  #
  # Returns an array of our defined networks.
  #
  # @return [Array<TestLab::Network>] An array of all defined networks.
  def networks
    TestLab::Network.all
  end

  # def config
  #   @labfile.config
  # end

  # Test Lab Alive?
  #
  # Are all of our nodes alive; that is up and running?
  #
  # @return [Boolean] True is all nodes are running; false otherwise.
  def alive?
    nodes.map(&:state).all?{ |state| state == :running }
  end

  # Test Lab Dead?
  #
  # Are any of our nodes dead; that is not up and running?
  #
  # @return [Boolean] False is all nodes are running; true otherwise.
  def dead?
    !alive?
  end

  # Test Lab Status
  #
  # Iterates our various DSL objects and calls their status methods pushing
  # the results through ZTK::Report to generate nice tabled output for us
  # indicating the state of the lab.
  #
  # This can only be run if the lab is alive.
  #
  # @return [Boolean] True if successful; false otherwise.
  def status
    if alive?
      %w(nodes networks containers).map(&:to_sym).each do |object_symbol|
        @@ui.stdout.puts
        @@ui.stdout.puts("#{object_symbol}:".upcase.green.bold)

        klass = object_symbol.to_s.singularize.capitalize
        status_keys = "TestLab::#{klass}::STATUS_KEYS".constantize

        ZTK::Report.new(:ui => @@ui).spreadsheet(self.send(object_symbol), status_keys) do |object|
          OpenStruct.new(object.status)
        end
      end

      true
    else
      @@ui.stdout.puts("Looks like your test lab is dead; fix this and try again.")

      false
    end
  end

  # Test Lab Setup
  #
  # Attempts to setup our lab topology.  This calls the setup method on all of
  # our nodes.
  #
  # @return [Boolean] True if successful.
  def setup
    self.dead? and raise TestLabError, "You must have a running node in order to setup your infrastructure!"

    node_method_proxy(:setup)

    true
  end

  # Test Lab Teardown
  #
  # Attempts to tearddown our lab topology.  This calls the teardown method on
  # all of our nodes.
  #
  # @return [Boolean] True if successful.
  def teardown
    self.dead? and raise TestLabError, "You must have a running node in order to teardown your infrastructure!"

    node_method_proxy(:teardown)

    true
  end

  # Node Method Proxy
  #
  # Iterates all of the lab nodes, sending the supplied method name and arguments
  # to each node.
  #
  # @return [Boolean] True if successful.
  def node_method_proxy(method_name, *method_args)
    nodes.map do |node|
      node.send(method_name.to_sym, *method_args)
    end

    true
  end

  # Provider Method Handler
  #
  # Proxies missing provider method calls to all nodes.
  #
  # @see TestLab::Provider::PROXY_METHODS
  def method_missing(method_name, *method_args)
    @@ui.logger.debug { "TESTLAB METHOD MISSING: #{method_name.inspect}(#{method_args.inspect})" }

    if TestLab::Provider::PROXY_METHODS.include?(method_name) # || %w(setup teardown).map(&:to_sym).include?(method_name))
      node_method_proxy(method_name, *method_args)
    else
      super(method_name, *method_args)
    end
  end

  def ui
    @@ui ||= ZTK::UI.new
  end

  # Class Helpers
  class << self

    # Test Lab User Interface
    #
    # Returns the instance of ZTK:UI the lab is using for its user interface.
    #
    # @return [ZTK::UI] Our user interface instance of ZTK::UI.
    def ui
      @@ui ||= ZTK::UI.new
    end

    # Test Lab Gem Directory
    #
    # Returns the directory path to where the gem is installed.
    #
    # @return [String] The directory path to the gem installation.
    def gem_dir
      directory = File.join(File.dirname(__FILE__), "..")
      File.expand_path(directory, File.dirname(__FILE__))
    end

    # Build Command Line
    #
    # Attempts to build a command line to a binary for us.  We use ZTK::Locator
    # to attempt to determine if we are using bundler binstubs; otherwise we
    # simply rely on */bin/env* to find the executable for us via the
    # *PATH* environment variable.
    #
    # @return [String] Constructed command line with arguments.
    def build_command_line(name, *args)
      executable = (ZTK::Locator.find('bin', name) rescue "/bin/env #{name}")
      [executable, args].flatten.compact.join(' ')
    end

  end

end

require 'zlib'
require 'socket'

require 'ztk'
require 'active_support/inflector'

require 'testlab/version'
require 'testlab/monkeys'

# TestLab - A framework for building lightweight virtual infrastructure using LXC
#
# The core concept with the TestLab is the *Labfile*.  This file dictates the
# topology of your virtual infrastructure.  With simple commands you can build
# and demolish this infrastructure on the fly for all sorts of purposes from
# automating infrastructure testing to testing new software to experimenting
# in general where you want to spin up alot of servers but do not want the
# overhead of virtualization.  At it's core TestLab uses Linux Containers (LXC)
# to accomplish this.
#
# @example Sample Labfile:
#   node 'vagrant' do
#
#     provider      TestLab::Provider::Vagrant
#     provisioners  [
#       TestLab::Provisioner::Raring,
#       TestLab::Provisioner::Bind
#     ]
#
#     config      ({
#       :vagrant => {
#         :id       => "chef-rubygem-#{TestLab.hostname}".downcase,
#         :cpus     => ZTK::Parallel::MAX_FORKS.div(2),                    # use half of the available processors
#         :memory   => ZTK::Parallel::MAX_MEMORY.div(3).div(1024 * 1024),  # use a third of available RAM
#         :box      => 'raring64',
#         :box_url  => 'https://dl.dropboxusercontent.com/u/22904185/boxes/raring64.box',
#         :file     => File.dirname(__FILE__)
#       },
#       :bind => {
#         :domain => "default.zone"
#       }
#     })
#
#     network 'labnet' do
#       provisioners  [TestLab::Provisioner::Route]
#       address       '10.10.0.1/16'
#       bridge        :br0
#     end
#
#     container "chef-server" do
#       distro        "ubuntu"
#       release       "precise"
#
#       provisioners   [
#         TestLab::Provisioner::Resolv,
#         TestLab::Provisioner::AptCacherNG,
#         TestLab::Provisioner::Apt,
#         TestLab::Provisioner::Chef::RubyGemServer
#       ]
#
#       user 'deployer' do
#         password         'deployer'
#         identity         File.join(ENV['HOME'], '.ssh', 'id_rsa')
#         public_identity  File.join(ENV['HOME'], '.ssh', 'id_rsa.pub')
#         uid              2600
#         gid              2600
#       end
#
#       interface do
#         network_id  'labnet'
#         name        :eth0
#         address     '10.10.0.254/16'
#         mac         '00:00:5e:63:b5:9f'
#       end
#     end
#
#     container "chef-client" do
#       distro        "ubuntu"
#       release       "precise"
#
#       provisioners  [
#         TestLab::Provisioner::Resolv,
#         TestLab::Provisioner::AptCacherNG,
#         TestLab::Provisioner::Apt,
#         TestLab::Provisioner::Chef::RubyGemClient
#       ]
#
#       user 'deployer' do
#         password         'deployer'
#         identity         File.join(ENV['HOME'], '.ssh', 'id_rsa')
#         public_identity  File.join(ENV['HOME'], '.ssh', 'id_rsa.pub')
#         uid              2600
#         gid              2600
#       end
#
#       interface do
#         network_id  'labnet'
#         name        :eth0
#         address     '10.10.0.20/16'
#         mac         '00:00:5e:b7:e5:15'
#       end
#     end
#
#   end
#
# @example TestLab can be instantiated easily:
#   log_file = File.join(Dir.pwd, "testlab.log")
#   logger = ZTK::Logger.new(log_file)
#   ui = ZTK::UI.new(:logger => logger)
#   testlab = TestLab.new(:ui => ui)
#
# @example We can control things via code easily as well:
#   testlab.create   # creates the lab
#   testlab.up       # ensures the lab is up and running
#   testlab.build    # build the lab, creating all networks and containers
#   testlab.demolish # demolish the lab, destroy all networks and containers
#
# @author Zachary Patten <zachary AT jovelabs DOT com>
class TestLab

  # TestLab Error Class
  class TestLabError < StandardError; end

  # Main Classes
  autoload :Container,   'testlab/container'
  autoload :Dependency,  'testlab/dependency'
  autoload :Interface,   'testlab/interface'
  autoload :Labfile,     'testlab/labfile'
  autoload :Network,     'testlab/network'
  autoload :Node,        'testlab/node'
  autoload :Provider,    'testlab/provider'
  autoload :Provisioner, 'testlab/provisioner'
  autoload :Source,      'testlab/source'
  autoload :Support,     'testlab/support'
  autoload :User,        'testlab/user'
  autoload :Utility,     'testlab/utility'

  include TestLab::Utility::Misc

  attr_accessor :config_dir
  attr_accessor :repo_dir
  attr_accessor :labfile_path

  def initialize(options={})
    self.ui        = (options[:ui] || ZTK::UI.new)
    self.class.ui  = self.ui

    _labfile_path  = (options[:labfile_path] || ENV['LABFILE'] || 'Labfile')
    @labfile_path  = ZTK::Locator.find(_labfile_path)

    @repo_dir      = (options[:repo_dir] || File.dirname(@labfile_path))

    @config_dir    = (options[:config_dir] || File.join(@repo_dir, ".testlab-#{TestLab.hostname}"))
    File.exists?(@config_dir) or FileUtils.mkdir_p(@config_dir)

    # @log_file      = (options[:log_file] || File.join(@repo_dir, "testlab-#{TestLab.hostname}.log") || STDOUT)
    # self.ui.logger = ZTK::Logger.new(@log_file)
  end

  # Boot TestLab
  #
  # Change to the defined repository directory and load the *Labfile*.
  #
  # @return [Boolean] True if successful.
  def boot
    TestLab::Utility.log_header(self).each { |line| self.ui.logger.info { line } }

    # Raise how many files we can have open to the hard limit.
    nofile_cur, nofile_max = Process.getrlimit(Process::RLIMIT_NOFILE)
    if nofile_cur != nofile_max

      # OSX likes to indicate we can set the infinity value here.
      #
      # Doing so causes the following exception to throw:
      #   Errno::EINVAL: Invalid argument - setrlimit
      #
      # In the event infinity is returned as the max value, use 4096 as the max
      # value.
      if (nofile_max == Process::RLIM_INFINITY)
        nofile_max = 4096
      end

      self.ui.logger.info { "Changing maximum open file descriptors from #{nofile_cur.inspect} to #{nofile_max.inspect}" }
      Process.setrlimit(Process::RLIMIT_NOFILE, nofile_max)
    end

    @labfile         = TestLab::Labfile.load(labfile_path)
    @labfile.testlab = self

    Dir.chdir(@repo_dir)
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

  # Test Lab Labfile
  #
  # Returns our top-level Labfile instance.
  #
  # @return [TestLab::Labfile] The top-level Labfile instance.
  def labfile
    @labfile
  end

  # Test Lab Configuration
  #
  # The hash defined in our *Labfile* DSL object which represents any high-level
  # lab configuration options.
  #
  # @return [Hash] A hash representing the labs configuration options.
  def config
    @labfile.config
  end

  # Test Lab Alive?
  #
  # Are all of our nodes up and running?
  #
  # @return [Boolean] True if all nodes are running; false otherwise.
  def alive?
    nodes.map(&:state).all?{ |state| state == :running }
  end

  # Test Lab Dead?
  #
  # Are any of our nodes not up and running?
  #
  # @return [Boolean] False is all nodes are running; true otherwise.
  def dead?
    !alive?
  end

  # Test Lab Create
  #
  # Attempts to create our lab topology.  This calls the create method on all of
  # our nodes.
  #
  # @return [Boolean] True if successful.
  def create
    method_proxy(:create)

    true
  end

  # Test Lab Destroy
  #
  # Attempts to destroy our lab topology.  This calls the destroy method on all of
  # our nodes.
  #
  # @return [Boolean] True if successful.
  def destroy
    reverse_method_proxy(:destroy)

    true
  end

  # Test Lab Up
  #
  # Attempts to up our lab topology.  This calls the up method on all of
  # our nodes.
  #
  # @return [Boolean] True if successful.
  def up
    method_proxy(:up)

    true
  end

  # Test Lab Down
  #
  # Attempts to down our lab topology.  This calls the down method on all of
  # our nodes.
  #
  # @return [Boolean] True if successful.
  def down
    reverse_method_proxy(:down)

    true
  end

  # Test Lab Provision
  #
  # Attempts to provision our lab topology.  This calls the provision method on
  # all of our nodes.
  #
  # @return [Boolean] True if successful.
  def provision
    method_proxy(:provision)

    true
  end

  # Test Lab Deprovision
  #
  # Attempts to tearddown our lab topology.  This calls the deprovision method
  # on all of our nodes.
  #
  # @return [Boolean] True if successful.
  def deprovision
    reverse_method_proxy(:deprovision)

    true
  end

  # Test Lab Build
  #
  # Attempts to build our lab topology.  This calls various methods on
  # all of our nodes, networks and containers.
  #
  # @return [Boolean] True if successful.
  def build
    method_proxy(:build)

    true
  end

  # Test Lab Demolish
  #
  # Attempts to demolish our lab topology.  This calls various methods on
  # all of our nodes, networks and containers.
  #
  # @return [Boolean] True if successful.
  def demolish
    reverse_method_proxy(:demolish)

    true
  end

  # Test Lab Bounce
  #
  # Attempts to bounce our lab topology.  This calls various methods on
  # all of our nodes, networks and containers.
  #
  # @return [Boolean] True if successful.
  def bounce
    self.down
    self.up

    true
  end

  # Test Lab Recycle
  #
  # Attempts to recycle our lab topology.  This calls various methods on
  # all of our nodes, networks and containers.
  #
  # @return [Boolean] True if successful.
  def recycle
    self.demolish
    self.build

    true
  end

  # Test Lab Doctor
  #
  # Attempts to analyze the lab for issues.
  #
  # @return [Boolean] True if everything is OK; false otherwise.
  def doctor
    results = Array.new

    if ((rlimit_nofile = Process.getrlimit(Process::RLIMIT_NOFILE)[0]) < 1024)
      @ui.stderr.puts(format_message("The maximum number of file handles is set to #{rlimit_nofile}!  Please raise it to 1024 or higher!".red.bold))
      results << false
    end

    results << nodes.all? do |node|
      node.doctor
    end

    results.flatten.compact.all?
  end

  # Node Method Proxy
  #
  # Iterates all of the lab nodes, sending the supplied method name and arguments
  # to each node.
  #
  # @return [Boolean] True if successful.
  def node_method_proxy(method_name, *method_args)
    nodes.each do |node|
      node.send(method_name.to_sym, *method_args)
    end

    true
  end

  # Method Proxy
  #
  # Iterates all of the lab objects sending the supplied method name and
  # arguments to each object.
  #
  # @return [Boolean] True if successful.
  def method_proxy(method_name, *method_args)
    nodes.each do |node|
      node.send(method_name, *method_args)
      node.networks.each do |network|
        network.send(method_name, *method_args)
      end
      node.containers.each do |container|
        container.send(method_name, *method_args)
      end
    end
  end

  # Reverse Method Proxy
  #
  # Iterates all of the lab objects sending the supplied method name and
  # arguments to each object.
  #
  # @return [Boolean] True if successful.
  def reverse_method_proxy(method_name, *method_args)
    nodes.reverse.each do |node|
      node.containers.reverse.each do |container|
        container.send(method_name, *method_args)
      end
      node.networks.reverse.each do |network|
        network.send(method_name, *method_args)
      end
      node.send(method_name, *method_args)
    end
  end

  # Provider Method Handler
  #
  # Proxies missing provider method calls to all nodes.
  #
  # @see TestLab::Provider::PROXY_METHODS
  def method_missing(method_name, *method_args)
    self.ui.logger.debug { "TESTLAB METHOD MISSING: #{method_name.inspect}(#{method_args.inspect})" }

    if TestLab::Provider::PROXY_METHODS.include?(method_name)
      node_method_proxy(method_name, *method_args)
    else
      super(method_name, *method_args)
    end
  end

  # Test Lab Class Methods
  #
  # These are special methods that we both include and extend on the parent
  # class.
  module DualMethods

    @@ui ||= nil

    # Get Test Lab User Interface
    #
    # Returns the instance of ZTK:UI the lab is using for its user interface.
    #
    # @return [ZTK::UI] Our user interface instance of ZTK::UI.
    def ui
      @@ui ||= ZTK::UI.new
    end

    # Set Test Lab User Interface
    #
    # Sets the instance of ZTK::UI the lab will use for its user interface.
    #
    # @param [ZTK:UI] value The instance of ZTK::UI to use for the labs user
    #   interface.
    #
    # @return [ZTK::UI]
    def ui=(value)
      @@ui = value
      value
    end

    # TestLab Hostname
    #
    # Gets the hostname portion of the fqdn for the current host.
    #
    # @return [String] The hostname for the current host.
    def hostname
      Socket.gethostname.split('.').first.strip
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
      executable = (ZTK::Locator.find('bin', name) rescue "/usr/bin/env #{name}")
      [executable, args].flatten.compact.join(' ')
    end

  end

  extend  TestLab::DualMethods
  include TestLab::DualMethods

end

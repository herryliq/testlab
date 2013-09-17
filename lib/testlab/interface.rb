class TestLab

  # Interface Error Class
  class InterfaceError < TestLabError; end

  # Interface Class
  #
  # @author Zachary Patten <zachary AT jovelabs DOT com>
  class Interface < ZTK::DSL::Base

    # Associations and Attributes
    belongs_to  :container,  :class_name => 'TestLab::Container'
    belongs_to  :network,    :class_name => 'TestLab::Network'

    attribute   :address
    attribute   :mac
    attribute   :name

    attribute   :primary,    :default => false

    def initialize(*args)
      @ui = TestLab.ui

      @ui.logger.debug { "Loading Interface" }
      super(*args)

      self.address ||= generate_ip
      self.mac     ||= generate_mac

      @ui.logger.debug { "Interface '#{self.id}' Loaded" }
    end

    # IP address for the interface
    def ip
      TestLab::Utility.ip(self.address)
    end

    # CIDR mask for the interface
    def cidr
      TestLab::Utility.cidr(self.address)
    end

    # Netmask for the interface
    def netmask
      TestLab::Utility.netmask(self.address)
    end

    # PTR record for the interface
    def ptr
      TestLab::Utility.ptr(self.address)
    end

    # Generate IP address
    #
    # Generates an RFC compliant private IP address.
    #
    # @return [String] A random, private IP address in the 192.168.0.1/24
    #   range.
    def generate_ip
      crc32  = Zlib.crc32(self.id.to_s)
      offset = crc32.modulo(255)

      octets = [ 192..192,
                 168..168,
                 0..254,
                 1..254 ]
      ip = Array.new
      for x in 1..4 do
        ip << octets[x-1].to_a[offset.modulo(octets[x-1].count)].to_s
      end
      "#{ip.join(".")}/24"
    end

    # Generate MAC address
    #
    # Generates an RFC compliant private MAC address.
    #
    # @return [String] A random, private MAC address.
    def generate_mac
      crc32  = Zlib.crc32(self.id.to_s)
      offset = crc32.modulo(255)

      digits = [ %w(0),
                 %w(0),
                 %w(0),
                 %w(0),
                 %w(5),
                 %w(e),
                 %w(0 1 2 3 4 5 6 7 8 9 a b c d e f),
                 %w(0 1 2 3 4 5 6 7 8 9 a b c d e f),
                 %w(5 6 7 8 9 a b c d e f),
                 %w(3 4 5 6 7 8 9 a b c d e f),
                 %w(0 1 2 3 4 5 6 7 8 9 a b c d e f),
                 %w(0 1 2 3 4 5 6 7 8 9 a b c d e f) ]
      mac = ""
      for x in 1..12 do
        mac += digits[x-1][offset.modulo(digits[x-1].count)]
        mac += ":" if (x.modulo(2) == 0) && (x != 12)
      end
      mac
    end

  end

end

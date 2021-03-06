module RegistrarClient
  class NameServer
    include Comparable

    attr_reader :name
    attr_accessor :ip_address

    def initialize(name)
      @name = name
    end

    def <=> other
      self.name <=> other.name
    end
  end
end

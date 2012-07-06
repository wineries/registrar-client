module RegistrarClient
  class Domain
    attr_reader :name

    attr_accessor :registrant
    attr_accessor :order

    attr_accessor :expiration
    attr_accessor :registration_status

    attr_accessor :lockable
    attr_accessor :real_time

    def initialize(name)
      @name = name
    end

    def lockable?
      !!lockable
    end

    def real_time?
      !!real_time
    end
  end
end

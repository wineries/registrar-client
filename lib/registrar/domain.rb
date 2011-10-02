module Registrar
  class Domain
    attr_reader :name

    attr_accessor :registrant
    attr_accessor :order

    attr_accessor :expiration
    attr_accessor :registration_status

    def initialize(name)
      @name = name
    end
  end
end

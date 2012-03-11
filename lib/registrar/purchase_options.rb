module Registrar
  class PurchaseOptions
    attr_writer :name_servers
    attr_writer :number_of_years
    attr_accessor :language

    def has_name_servers?
      !name_servers.empty?
    end

    def name_servers
      @name_servers ||= []
    end

    def has_extended_attributes?
      !extended_attributes.empty?
    end

    def extended_attributes
      @extended_attributes ||= []
    end

    def number_of_years
      @number_of_years ||= 1
    end

  end
end

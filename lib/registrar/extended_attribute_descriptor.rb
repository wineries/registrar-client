module Registrar
  class ExtendedAttributeDescriptor 
    attr_accessor :name
    attr_accessor :description
    attr_accessor :required
    attr_accessor :child
    attr_accessor :application
    attr_accessor :user_defined
    attr_accessor :options

    alias :required? :required
    alias :child? :child
    alias :user_defined? :user_defined

    def initialize
      @options = []
    end
  end
end

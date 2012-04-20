module Registrar
  class ExtendedAttributeDescriptor 
    attr_accessor :name
    attr_accessor :description
    attr_accessor :required
    attr_accessor :child
    attr_accessor :application
    attr_accessor :user_defined
    attr_accessor :options
    attr_accessor :apply_to_registrar

    alias :required? :required
    alias :child? :child
    alias :user_defined? :user_defined
    alias :apply_to_registrar? :apply_to_registrar

    def initialize
      @options = []
    end

    def serializable_hash 
      {
        'name' => name, 
        'description' => description,
        'required' => required,
        'options' => options
      }
    end

  end
end

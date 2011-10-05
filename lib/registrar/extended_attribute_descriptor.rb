module Registrar
  class ExtendedAttributeDescriptor 
    attr_accessor :name
    attr_accessor :description
    attr_accessor :required

    alias :required? :required
  end
end

require 'httparty'

module Registrar
  # Error indicating that a registrar provider is required but none was 
  # available.
  class ProviderRequiredError < RuntimeError
  end

  # Base error for any errors encountered while communicating with a registrar.
  class RegistrarError < RuntimeError
  end
end

require 'registrar/client'

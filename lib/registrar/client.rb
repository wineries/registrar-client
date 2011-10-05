require 'registrar/contact'
require 'registrar/domain'
require 'registrar/purchase_options'
require 'registrar/renewal_options'
require 'registrar/extended_attribute'
require 'registrar/name_server'
require 'registrar/order'

module Registrar #:nodoc:
  # This class provides a generic client interface for accessing domain
  # registrars as a domain reseller. The interface provides methods for 
  # checking domain availability, registering domain names and finding
  # details on domains that are already registered.
  #
  # For examples of how to use this interface please see README.textile.
  class Client
    attr_reader :provider

    # Initialize the client with an provider.
    #
    # adapter - The provider instance.
    def initialize(provider)
      @provider = provider 
    end

    # Parse a domain name into it's top-level domain part and its remaining
    # parts.
    #
    # name - The fully-qualified domain name to parse
    #
    # Returns an array with two elements. The first element is a string with
    # all parts of the domain minus the TLD. The last element is the TLD
    # string.
    def parse(name)
      name = name.downcase
      parse_cache[name] ||= provider.parse(name)
    end

    def parse_cache
      @parse_cache ||= {}
    end
    private :parse_cache

    # Check for the availability of a domain.
    #
    # name - The fully-qualified domain name to check.
    #
    # Returns true if the name is available.
    def available?(name)
      provider.available?(name.downcase)
    end

    # Find a domain and return an object representing that domain.
    # If the domain is not registered or is registered with another reseller then
    # this method will return nil.
    #
    # name - The fully-qualified domain name.
    #
    # Returns a Registrar::Domain object.
    def find(name)
      provider.find(name.downcase)
    end

    # Purchase a domain name for the given registrant.
    #
    # name - The fully-qualified domain name to purchase.
    # registrant - A complete Registrar::Contact instance.
    # registration_options - Optional Registrar::RegistrationOptions instance.
    #
    # Returns a Registrar::Order
    def purchase(name, registrant, registration_options=nil)
      provider.purchase(name.downcase, registrant, registration_options)
    end

    # Renew a domain name.
    #
    # name - The fully-qualified domain name to renew.
    # renewal_options - Optional Registrar::RenewalOptions instance.
    #
    # Returns a Registrar::Order
    def renew(name, renewal_options=nil)
      provider.renew(name.downcase, renewal_options)
    end

    # Check if the name servers of a given donain
    #
    # name - The fully-qualified domain name.
    #
    # Returns a list of name servers attached to this domain
    def check_nameservers(name)
      provider.check_nameservers(name.downcase)
    end
  end
end

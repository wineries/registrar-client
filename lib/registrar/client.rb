require 'registrar/contact'
require 'registrar/domain'
require 'registrar/purchase_options'
require 'registrar/renewal_options'
require 'registrar/extended_attribute_descriptor'
require 'registrar/extended_attribute_option_descriptor'
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
    alias :find_domain :find

    # Get a set of extended attribute descriptor objects. This set can be
    # used to determine what extended registry attributes must be collected
    # for the given domain.
    #
    # name - The fully-qualified domain name.
    # 
    # Returns an array of Registrar::ExtendedAttribute objects.
    def extended_attributes(name)
      provider.extended_attributes(name)
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

    # Get the order identified by the given ID
    #
    # id - The order ID
    # 
    # Returns a Registrar::Order
    def order(id)
      provider.order(id)
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

    # Return true if the domain is set up for auto renewal
    #
    # name - The fully-qualified domain name
    #
    # Returns true if the domain should be auto renewed by the registrar
    def auto_renew?(name)
      provider.auto_renew?(name)
    end

    # Enable auto-renewal for a domain
    #
    # name - The name to auto renew
    #
    # Returns true of auto-renewal was enabled
    def enable_auto_renewal(name)
      provider.enable_auto_renewal(name) 
    end
    alias :enable_auto_renew :enable_auto_renewal

    # Disable auto-renewal for a domain
    #
    # name - The name that has auto renewal enabled
    #
    # Returns true if the auto-renewal was disabled
    def disable_auto_renewal(name)
      provider.disable_auto_renewal(name) 
    end
    alias :disable_auto_renew :disable_auto_renewal

    # List name servers for a domain. 
    #
    # name - The fully-qualified domain name.
    #
    # Returns a list of name servers attached to this domain
    def name_servers(name)
      provider.name_servers(name.downcase)
    end
    alias :nameservers :name_servers

    # Set the name servers for a given name.
    #
    # name - The fully-qualified domain name.
    # name_servers - A set of name server names as strings.
    #
    # Returns the list of name servers
    def set_name_servers(name, name_servers=[])
      provider.set_name_servers(name, name_servers)
    end

    # Find a name server by name.
    #
    # name - The name server name
    #
    # Returns a Registrar::NameServer instance
    def find_name_server(name)
      provider.find_name_server(name)
    end

    # Registers a name server with various registries
    #
    # name_server - The NameServer to register, including IP address
    def register_name_server(name_server)
      provider.register_name_server(name_server)
    end

    # Return the minimum number of years required to register a domain.
    #
    # tld - The TLD.
    #
    # Returns the minimum number of years required for registration.
    def minimum_number_of_years(tld)
      provider.minimum_number_of_years(tld.downcase)
    end

    # Return the retail transfer price for the given TLD.
    #
    # tld - The TLD.
    #
    # Returns the transfer price.
    def tld_retail_transfer_price(tld)
      provider.tld_retail_transfer_price(tld)
    end

    def contacts(name)
      provider.contacts(name)
    end

    def update_registrant(name, contact)
      provider.update_registrant(name, contact)
    end

    def update_contacts(name, contact)
      provider.update_contacts(name, contact)
    end

    def update_technical_contact(name, contact)
      provider.update_technical_contact(name, contact)
    end

    def update_administrative_contact(name, contact)
      provider.update_administrative_contact(name, contact)
    end

    def update_aux_billing_contact(name, contact)
      provider.update_aux_billing_contact(name, contact)
    end
  end
end

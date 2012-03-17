require 'httparty'
require 'tzinfo'

require 'registrar/provider/enom/contact'
require 'registrar/provider/enom/extended_attribute'
require 'registrar/provider/enom/order'

module Registrar
  module Provider
    # Implementation of a registrar provider for Enom (http://www.enom.com/).
    class Enom
      include HTTParty

      attr_accessor :url, :username, :password

      def initialize(url, username, password)
        @url = url
        @username = username
        @password = password
      end

      def parse(name)
        query = base_query.merge('Command' => 'ParseDomain')
        response = execute(query.merge('PassedDomain' => name))
        
        [response['ParseDomain']['SLD'], response['ParseDomain']['TLD']] 
      end

      def available?(name)
        sld, tld = parse(name)
        
        query = base_query.merge('Command' => 'Check')
        response = execute(query.merge('SLD' => sld, 'TLD' => tld))
        
        response['RRPCode'] == '210'
      end

      def find(name)
        sld, tld = parse(name)
        query = base_query.merge('Command' => 'GetDomainInfo')
      
        response = execute(query.merge('SLD' => sld, 'TLD' => tld))
        
        domain = Registrar::Domain.new(name) 
        domain.expiration = response['GetDomainInfo']['status']['expiration']
        domain.registration_status = response['GetDomainInfo']['status']['registrationstatus']
        domain
      end

      def purchase(name, registrant, purchase_options=nil)
        purchase_options ||= Registrar::PurchaseOptions.new

        sld, tld = parse(name)
        query = base_query.merge('Command' => 'Purchase', 'SLD' => sld, 'TLD' => tld)
        registrant = Enom::Contact.new(registrant)
             
        if registrant
          query.merge!(registrant.to_query("Registrant"))
          query.merge!(registrant.to_query("AuxBilling"))
          query.merge!(registrant.to_query("Tech"))
          query.merge!(registrant.to_query("Admin"))
        end

        if purchase_options.has_name_servers? 
          query['IgnoreNSFail'] = 'Yes'
          purchase_options.name_servers.each_with_index do |name_server, i|
            case name_server
            when String
              query["NS#{i+1}"] = name_server
            else
              query["NS#{i+1}"] = name_server.name
            end
            
          end
        else
          query['UseDNS'] = 'default'
        end

        if purchase_options.has_extended_attributes?
          extended_attributes = purchase_options.extended_attributes.map { |a| Enom::ExtendedAttribute.new(a) }
          extended_attributes.each do |extended_attribute| 
            query[extended_attribute.name] = extended_attribute.value
          end
        end

        query['NumYears'] = purchase_options.number_of_years || minimum_number_of_years(tld)
        query['IDNCode'] = purchase_options.language if purchase_options.language

        response = execute(query)

        registrant.identifier = response['RegistrantPartyID']

        domain = Registrar::Domain.new(name) 
        domain.registrant = registrant
        domain.lockable = response['IsLockable'].downcase == 'true'
        domain.real_time = response['IsRealTimeTLD'].downcase == 'true'
        order = order(response['OrderID'])
        order.domains << domain
        domain.order = order
        order
      end

      def renew(name, renewal_options=nil)
        renewal_options ||= Registrar::RenewalOptions.new
        sld, tld = parse(name)
        query = base_query.merge('Command' => 'Extend', 'SLD' => sld, 'TLD' => tld)
        query = query.merge('NumYears' => renewal_options.number_of_years)
        response = execute(query)
        response['Extension'] && response['Extension'].downcase == 'successful'
      end

      def order(id)
        query = base_query.merge('Command' => 'GetOrderDetail', 'OrderID' => id.to_s)
        response = execute(query)

        order = Enom::Order.new(response['Order']['OrderID'])
        order.order_date = response['Order']['OrderDate']
        order.order_status = response['Order']['OrderDetail']['OrderStatus']
        order.status = response['Order']['OrderDetail']['Status']
        order.to_order
      end

      def name_servers(name)
        sld, tld = parse(name)
        query = base_query.merge('Command' => 'GetDNS', 'TLD' => tld, 'SLD' => sld)
        response = execute_command(query)
        [response['dns']].flatten
      end
      alias :nameservers :name_servers

      def set_name_servers(name, name_servers=[])
        sld, tld = parse(name)
        query = base_query.merge('Command' => 'ModifyNS', 'TLD' => tld, 'SLD' => sld)

        name_server_hash = {}
        if name_servers.length == 0
          name_server_hash["NS1"] = ""
        else
          name_servers.each_with_index do |ns_name, index|
            name_server_hash["NS#{index + 1}"] = ns_name
          end
        end
        query = query.merge(name_server_hash)

        response = execute_command(query)

        name_servers
      end

      def find_name_server(name)
        query = base_query.merge('Command' => 'CheckNSStatus', 'CheckNSName' => name)
        response = execute_command(query)
        
        if response['NsCheckSuccess'] == '1'
          name_server = Registrar::NameServer.new(response['CheckNsStatus']['name'])
          name_server.ip_address = response['CheckNsStatus']['ipaddress']
          name_server
        else
          raise RuntimeError, "Name server not found for #{name}"
        end 
      end
      
      def register_name_server(name_server)
        query = base_query.merge('Command' => 'RegisterNameServer', 'Add' => 'true', 'NSName' => name_server.name, 'IP' => name_server.ip_address)
        response = execute_command(query)

        if response['RRPCode'] == '200'
          name_server = Registrar::NameServer.new(response['RegisterNameserver']['NS'])
          name_server.ip_address = response['RegisterNameserver']['IP']
          name_server
        else
          raise RuntimeError, "Unable to create name server: #{response['RRPText']}"
        end
      end

      def extended_attributes(name)
        sld, tld = parse(name)
        query = base_query.merge('Command' => 'GetExtAttributes', 'TLD' => tld)
        response = execute(query)
        return nil unless response['Attributes']
        [response['Attributes']['Attribute']].flatten.map do |enom_attribute|
          extended_attribute = Registrar::ExtendedAttributeDescriptor.new
          extended_attribute.name = enom_attribute['Name']
          extended_attribute.description = enom_attribute['Description']
          extended_attribute.child = enom_attribute['IsChild'] == '1'
          extended_attribute.required = enom_attribute['Required'] == '1'
          extended_attribute.application = enom_attribute['Application']
          extended_attribute.user_defined = enom_attribute['UserDefined'] == 'True'

          if enom_attribute['Options']
            extended_attribute.options = [enom_attribute['Options']['Option']].flatten.map do |enom_option|
              option = Registrar::ExtendedAttributeOptionDescriptor.new
              option.title = enom_option['Title']
              option.value = enom_option['Value']
              option.description = enom_option['Description']
              option
            end
          end

          extended_attribute
        end
      end

      def minimum_number_of_years(tld)
        {
          'co.uk' => 2,
          'org.uk' => 2,
          'nu' => 2,
          'tm' => 10,
          'com.mx' => 2,
          'me.uk' => 2
        }[tld] || 1
      end

      def tld_retail_transfer_price(tld)
        Enom::PricingEngine.tld_retail_transfer_price(tld)
      end

      # Get a Hash of all of the contacts for the domain. The Hash will have the following
      # key/value pairs:
      #
      #  * :registrant => The domain registrant
      #  * :aux_billing => An customer specified billing contact
      #  * :tech => The technical contact for the domain
      #  * :admin => The administrative contact for the domain
      #  * :billing => The Enom billing contact (DNSimple)
      def contacts(domain)
        sld, tld = parse(domain.name)
        query = base_query.merge('Command' => 'GetContacts', 'TLD' => tld, 'SLD' => sld)

        response = execute(query)

        contacts = {}
        registrant_hash = response['GetContacts']['Registrant']
        contacts[:registrant] = Enom::Contact.from_enom('Registrant', registrant_hash)
        aux_billing_hash = response['GetContacts']['AuxBilling']
        contacts[:aux_billing] = Enom::Contact.from_enom('AuxBilling', aux_billing_hash) 

        tech_hash = response['GetContacts']['Tech']
        contacts[:tech] = Enom::Contact.from_enom('Tech', tech_hash)

        admin_hash = response['GetContacts']['Admin']
        contacts[:admin] = Enom::Contact.from_enom('Admin', admin_hash)

        billing_hash = response['GetContacts']['Billing']
        contacts[:billing] = Enom::Contact.from_enom('Billing', billing_hash)

        contacts
      end

      # Update the registrant information for a domain. For some TLDs this will include
      # providing extended attributes. If the TLD does not require extended attributes
      # then send nil or an empty Hash for the extended_attributes argument.
      def update_registrant(domain, registrant, extended_attributes=nil)
        registrant = Enom::Contact.new(registrant)

        sld, tld = parse(domain.name)
        query = base_query.merge(
          'Command' => 'Contacts',
          'TLD' => tld,
          'SLD' => sld
        )

        query = query.merge('ContactType' => 'Registrant')
        query = query.merge(registrant.to_query('Registrant'))

        if extended_attributes
          extended_attributes.each do |name, value| 
            query[name] = value
          end
        end

        response = execute_command(query) # TODO: should something else be returned here?
      end

      # Update the tech, aux billing and administrative contacts for the domain. Right
      # now the same contact must be used for all of these contact types.
      def update_contacts(domain, contact)
        contact = Enom::Contact.new(contact)

        sld, tld = parse(domain.name)
        base_query = base_query.merge(
          'Command' => 'Contacts',
          'TLD' => tld,
          'SLD' => sld
        )

        query = base_query.merge('ContactType' => 'Tech')
        query = query.merge(contact.to_query('Tech'))
        response = execute_command(query)

        query = base_query.merge('ContactType' => 'Admin')
        query = query.merge(contact.to_query('Admin'))
        response = execute_command(query)

        query = base_query.merge('ContactType' => 'AuxBilling')
        query = query.merge(contact.to_query('AuxBilling'))
        response = execute(query)

        contacts(domain)
      end

      # Update the tech contact for the domain.
      def update_technical_contact(domain, contact)
        contact = Enom::Contact.new(contact)

        sld, tld = parse(domain.name)
        query = base_query.merge(
          'Command' => 'Contacts',
          'TLD' => tld,
          'SLD' => sld
        )

        query = query.merge('ContactType' => 'Tech')
        query = query.merge(contact.to_query('Tech'))
        response = execute(query)
        contacts(domain)[:tech]
      end

      # Update the admin contact for the domain.
      def update_administrative_contact(domain, contact)
        contact = Enom::Contact.new(contact)

        sld, tld = parse(domain.name)
        base_query = base_query.merge(
          'Command' => 'Contacts',
          'TLD' => tld,
          'SLD' => sld
        )

        query = base_query.merge('ContactType' => 'Admin')
        query = query.merge(contact.to_query('Admin'))
        response = execute(query)
        contacts(domain)[:admin]
      end

      # Update the aux billing contact for the domain.
      def update_aux_billing_contact(domain, contact)
        contact = Enom::Contact.new(contact)

        sld, tld = parse(domain.name)
        query = base_query.merge(
          'Command' => 'Contacts',
          'TLD' => tld,
          'SLD' => sld
        )

        query = query.merge('ContactType' => 'AuxBilling')
        query = query.merge(contact.to_query('AuxBilling'))
        response = execute(query)
        contacts(domain)[:aux_billing]
      end

      private
      def execute(query)
        Encoding.default_internal = Encoding.default_external = "UTF-8"
        options = {:query => query, :parser => EnomParser}
        response = self.class.get(url, options)['interface_response']
        raise Registrar::RegistrarError.new("Response from Enom was nil") if response.nil? 
        raise EnomError.new(response) if response['ErrCount'] != '0'
        response
      end
      alias :execute_command :execute

      def base_query
        {
          'UID' => username,
          'PW' => password,
          'ResponseType' => 'XML'
        }
      end
      
    end

    class EnomError < Registrar::RegistrarError 
      attr_reader :response
      attr_reader :errors

      def initialize(response)
        @response = response
        @errors = []

        response['errors'].each do |k, err|
          @errors << err
        end

        super response['errors'].values.join(", ")
      end
    end

    class EnomParser < HTTParty::Parser
      def body 
        @body.force_encoding('UTF-8')
      end
    end
  end
end

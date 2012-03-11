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
            query["NS#{i+1}"] = name_server.name
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
         
        response = execute(query)

        registrant.identifier = response['RegistrantPartyID']

        domain = Registrar::Domain.new(name) 
        domain.registrant = registrant
        order = order(response['OrderID'])
        order.domains << domain
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
        
      end
      alias :nameservers :name_servers

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

      private
      def execute(query)
        Encoding.default_internal = Encoding.default_external = "UTF-8"
        options = {:query => query, :parser => EnomParser}
        response = self.class.get(url, options)['interface_response']
        raise Registrar::RegistrarError.new("Response from Enom was nil") if response.nil? 
        raise EnomError.new(response) if response['ErrCount'] != '0'
        response
      end

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

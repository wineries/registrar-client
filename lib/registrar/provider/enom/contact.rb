module Registrar
  module Provider
    # :nodoc:
    class Enom
      # Contact object that wraps a generic contact and can be used to produce and parse
      # wire-level representations of Enom contacts.
      class Contact
        attr_reader :contact

        def initialize(contact)
          raise ArgumentError, "Contact is required" unless contact
          @contact = contact
        end

        def identifier
          contact.identifier
        end

        def identifier=(identifier)
          contact.identifier = identifier
        end

        # Returns a Hash that can be merged into a query.
        # Type should be one of the following: Registrant, AuxBilling, Tech, Admin
        def to_query(type)
          {
            "#{type}Address1" => contact.address_1,
            "#{type}Address2" => contact.address_2,
            "#{type}City" => contact.city,
            "#{type}Country" => contact.country,
            "#{type}EmailAddress" => contact.email,
            "#{type}Fax" => contact.fax,
            "#{type}FirstName" => contact.first_name,
            "#{type}LastName" => contact.last_name,
            "#{type}JobTitle" => contact.job_title,
            "#{type}OrganizationName" => contact.organization_name,
            "#{type}Phone" => contact.phone,
            "#{type}PhoneExt" => contact.phone_ext,
            "#{type}PostalCode" => contact.postal_code,
            "#{type}StateProvince" => contact.state_province,
            "#{type}StateProvinceChoice" => contact.state_province_choice
          }
        end

        def self.from_response(type, attributes)
          contact = self.new
          contact.party_id = attributes["#{type}PartyID"]
          contact.address_1 = attributes["#{type}Address1"]
          contact.address_2 = attributes["#{type}Address2"]
          contact.city = attributes["#{type}City"]
          contact.country = attributes["#{type}Country"]
          contact.email = attributes["#{type}EmailAddress"]
          contact.fax = attributes["#{type}Fax"]
          contact.first_name = attributes["#{type}FirstName"]
          contact.last_name = attributes["#{type}LastName"]
          contact.job_title = attributes["#{type}JobTitle"]
          contact.organization_name = attributes["#{type}OrganizationName"]
          contact.phone = attributes["#{type}Phone"]
          contact.phone_ext = attributes["#{type}PhoneExt"]
          contact.postal_code = attributes["#{type}PostalCode"]
          contact.state_province = attributes["#{type}StateProvince"]
          contact.state_province_choice = attributes["#{type}StateProvinceChoice"]
          contact
        end
      end
    end
  end
end

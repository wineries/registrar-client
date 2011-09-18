require 'spec_helper'
require 'registrar/provider/opensrs/contact_set'

describe Registrar::Provider::OpenSRS::ContactSet do
  context "with contacts" do
    let(:contact) { Registrar::Contact.new(
      :identifier => '12345',
      :first_name => 'John',
      :last_name => 'Doe',
      :address_1 => '1 SW 1st Street',
      :address_2 => 'Apt 305',
      :city => 'Miami',
      :state_province => 'Florida',
      :country => 'US',
      :postal_code => '33143',
      :phone => '321 213 3656',
      :email => 'john.doe@example.com'
    ) }
    let(:opensrs_contacts) { {'12345' => Registrar::Provider::OpenSRS::Contact.new(contact) }}
    it "produces xml" do
      builder = Builder::XmlMarkup.new
      contact_set = Registrar::Provider::OpenSRS::ContactSet.new(opensrs_contacts)
      contact_set.to_xml(builder).should eq('<dt_assoc><item key=\"12345\"><dt_assoc><item key=\"first_name\">John</item><item key=\"last_name\">Doe</item><item key=\"phone\">321 213 3656</item><item key=\"fax\"></item><item key=\"email\">john.doe@example.com</item><item key=\"org_name\"></item><item key=\"address1\">1 SW 1st Street</item><item key=\"address2\">Apt 305</item><item key=\"city\">Miami</item><item key=\"state\">Florida</item><item key=\"country\">US</item><item key=\"postal_code\">33143</item></dt_assoc></item></dt_assoc>')
    end
  end

end

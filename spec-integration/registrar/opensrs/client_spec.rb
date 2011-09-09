require 'spec_helper'

require 'httparty'
require 'registrar/provider/opensrs'
require 'registrar/provider/opensrs/tld_data'
require 'registrar/provider/opensrs/tld_data_us'
require 'registrar/provider/opensrs/name_server_list'

describe "registrar client integration with opensrs" do
  let(:config) { YAML.load_file('spec-integration/opensrs.yml') }
  let(:url) { config['url'] }
  let(:username) { config['username'] }
  let(:private_key) { config['private_key'] }

  let(:provider) { Registrar::Provider::OpenSRS.new(url, username, private_key) }
  let(:client) { Registrar::Client.new(provider) }

  let(:name) { "example.com" }

  let(:registrant) do
    Registrar::Contact.new({
      :first_name => 'Anthony',
      :last_name => 'Eden',
      :organization_name => 'NA',
      :address_1 => '123 SW 1st Street',
      :city => 'Anywhere',
      :state_province => 'CA',
      :country => 'US',
      :postal_code => '12121',
      :phone => '+1.4445551212',
      :email => 'anthony@dnsimple.com'
    })
  end

  describe "#available?" do
    context "for an available domain" do
      it "returns true" do
        client.available?("test-#{Time.now.to_i}-#{rand(10000)}.com").should be_true
      end

      it 'returns true for an es domain' do
        client.available?("test-#{Time.now.to_i}-#{rand(10000)}.es").should be_true
      end
    end
    context "for an unavailable domain" do
      it "returns false" do
        client.available?("google.com").should be_false
      end
    end
  end

  shared_examples "a real-time domain without extended attributes" do
    describe "#purchase" do
      let(:order) { client.purchase(name, registrant) }
      it "returns a completed order" do
        order.should be_complete
      end
    end
  end

  shared_examples "a real-time domain with extended attributes" do
    describe "#purchase" do
      let(:order) { client.purchase(name, registrant, purchase_options) }
      it "returns a completed order" do
        order.should be_complete
      end
      it "has a :closed status" do
        order.status.should eq(:closed)
      end
      it "has the domain in the order" do
        order.domains.should_not be_empty
        order.domains[0].name.should eq(name)
      end
    end
  end

  describe "#purchase" do
    context "for an available .com" do
      it_behaves_like "a real-time domain without extended attributes" do
        let(:name) { "test-#{Time.now.to_i}-#{rand(10000)}.com" }
      end
    end

    context "for an available .es" do
      it_behaves_like "a real-time domain without extended attributes" do
        let(:name) { "test-#{Time.now.to_i}-#{rand(10000)}.es" }
      end
    end

    context "for an available .us" do
      it_behaves_like "a real-time domain with extended attributes" do
        let(:name) { "test-#{Time.now.to_i}-#{rand(10000)}.us" }
        let(:purchase_options) do
          purchase_options = Registrar::PurchaseOptions.new
          purchase_options.extended_attributes << Registrar::ExtendedAttribute.new('us', :Nexus, :"US Citizen")
          purchase_options.extended_attributes << Registrar::ExtendedAttribute.new('us', :Purpose, :"Personal")
          purchase_options
        end
      end
    end

    context 'name servers' do
      let(:name) { "test-#{Time.now.to_i}-#{rand(10000)}.com" }
      let(:nameserver){ Registrar::NameServer.new('ns1.dnsimple.com') }
      let(:nameserver2){ Registrar::NameServer.new('ns2.dnsimple.com') }
      let(:purchase_options) do
        purchase_options = Registrar::PurchaseOptions.new
        purchase_options.name_servers << nameserver
        purchase_options.name_servers << nameserver2
        purchase_options
      end

      it 'should have the nameservers assigned to the domain' do
        client.purchase(name, registrant, purchase_options)
        client.check_nameservers(name).should include nameserver, nameserver2
      end
    end

  end
end

require 'spec_helper'
require 'registrar/provider/enom'

describe Registrar::Provider::Enom do
  let(:url) { "http://provider/api" }
  let(:username) { "client_username" }
  let(:password) { "client_password" }
  let(:client) { Registrar::Provider::Enom.new(url, username, password) }

  it "is initialized with the url, username and password" do
    lambda { client }.should_not raise_error
  end

  let(:name) { "example.com" }

  let(:base_args) do
    {
      'UID' => username, 
      'PW' => password, 
      'ResponseType' => 'XML'
    }
  end

  describe "#parse" do
    let(:args) do
      base_args.merge({
        'Command' => 'ParseDomain', 
        'PassedDomain' => 'example.com'
      })
    end
    let(:response) do
      {'ParseDomain' => {'SLD' => 'example', 'TLD' => 'com'}}
    end

    it "parses a name" do
      client.expects(:execute).with(args).returns(response)
      client.parse(name).should eq(['example','com'])
    end
  end

  describe "#available?" do
    let(:args) do
      base_args.merge({
        'Command' => 'Check',
        'SLD' => 'example',
        'TLD' => 'com'
      })
    end

    context "for an available domain" do
      let(:response) { {'RRPCode' => '210'} }
      it "returns true" do
        client.stubs(:parse).returns(['example','com'])
        client.expects(:execute).with(args).returns(response)
        client.available?(name).should be_true
      end
    end
    context "for an unavailable domain" do
      let(:response) { {'RRPCode' => '211'} }
      it "returns false" do
        client.stubs(:parse).returns(['example','com'])
        client.expects(:execute).with(args).returns(response)
        client.available?(name).should be_false
      end
    end
  end

  describe "#purchase" do
    let(:order_id) { '123456' }
    let(:registrant_party_id) { '333444555' }
    let(:registrant) do
      Registrar::Contact.new(
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
      )
    end
    let(:enom_registrant) do
      Registrar::Provider::Enom::Contact.new(registrant)
    end

    let(:response) do 
      {
        'OrderID' => order_id, 
        'RegistrantPartyID' => registrant_party_id
      }
    end

    let(:order) do
      order = Registrar::Provider::Enom::Order.new(order_id)
      order.status = 'Successful'
      order.order_status = 'Complete'
      order
    end
    let(:purchase_options) { nil }
    let(:base_purchase_args) do
      args = base_args.merge({
        'Command' => 'Purchase',
        'SLD' => 'example',
        'TLD' => 'com',
        'NumYears' => 1
      })
      args.merge!(enom_registrant.to_query("Registrant"))
      args.merge!(enom_registrant.to_query("Admin"))
      args.merge!(enom_registrant.to_query("AuxBilling"))
      args.merge!(enom_registrant.to_query("Tech"))
      args
    end

    shared_examples "the domain purchase method" do
      it "returns a complete order" do
        client.expects(:execute).with(args).returns(response)
        client.stubs(:parse).returns(['example','com'])
        client.expects(:order).with(order_id).returns(order.to_order)
        order = client.purchase(name, registrant, purchase_options)
        order.should be_complete
      end
    end

    context "without purchase options" do
      let(:args) do
        base_purchase_args.merge(
          'UseDNS' => 'default'
        )
      end
      it_behaves_like "the domain purchase method"
    end

    context "with the name servers specified" do
      let(:args) do
        base_purchase_args.merge(
          'IgnoreNSFail' => 'Yes', 
          'NS1' => 'ns1.example.com'
        )
      end

      let(:purchase_options) do
        purchase_options = Registrar::PurchaseOptions.new
        purchase_options.name_servers << Registrar::NameServer.new('ns1.example.com')
        purchase_options
      end
      it_behaves_like "the domain purchase method"
    end

  end

  describe "#renew" do
    let(:args) do
      base_args.merge({
        'Command' => 'Extend',
        'SLD' => 'example',
        'TLD' => 'com',
        'NumYears' => 1
      })
    end
    let(:response) { {'Extension' => 'Successful'} }
    it "renews the domain for 1 year" do
      client.stubs(:parse).returns(['example','com'])
      client.expects(:execute).with(args).returns(response)
      client.renew(name).should be_true
    end
  end

  describe "#order" do

  end

  describe "#name_servers" do

  end

  describe "#minimum_number_of_years" do
    context "for a standard TLD" do
      it "returns 1" do
        client.minimum_number_of_years('com').should eq(1)
      end
    end
    it "returns 2 for co.uk" do
      client.minimum_number_of_years('co.uk').should eq(2)
    end
    it "returns 2 for org.uk" do
      client.minimum_number_of_years('org.uk').should eq(2)
    end
    it "returns 2 for nu" do
      client.minimum_number_of_years('nu').should eq(2)
    end
    it "returns 10 for tm" do
      client.minimum_number_of_years('tm').should eq(10)
    end
    it "returns 2 for com.mx" do
      client.minimum_number_of_years('com.mx').should eq(2)
    end
    it "returns 2 for me.uk" do
      client.minimum_number_of_years('me.uk').should eq(2)
    end
  end
end

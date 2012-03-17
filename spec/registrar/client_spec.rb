require 'spec_helper'

describe Registrar::Client do

  let(:provider) { stub("Provider") }

  context "when instantiated" do
    it "requires a provider" do
      lambda { Registrar::Client.new }.should raise_error
    end
    it "instantiates without error" do
      lambda { Registrar::Client.new(provider) }.should_not raise_error
    end
  end

  let(:client) { Registrar::Client.new(provider) }
  let(:name) { "example.com" }
  let(:tld) { "com" }
  let(:domain) { Registrar::Domain.new(name) }

  describe "#parse" do
    it "returns an array of the name parts" do
      provider.expects(:parse).with(name).returns(['example','com'])
      client.parse(name).should eq(['example','com']) 
    end
  end

  describe "#available?" do
    it "returns true if a domain is available" do
      provider.expects(:available?).with(name).returns(true)
      client.available?(name).should be_true
    end
  end

  describe "#find" do
    it "delegates to the provider" do
      provider.expects(:find).with(name).returns(domain)
      client.find(name).should_not be_nil
    end
  end

  describe "#extended_attributes" do
    it "returns a collection of extended attribute definitions" do
      provider.expects(:extended_attributes).with(name).returns([])
      client.extended_attributes(name).should_not be_nil
    end
  end

  describe "#minimum_number_of_years" do
    it "delegates to the provider implementation" do
      provider.expects(:minimum_number_of_years).with(name).returns(1)
      client.minimum_number_of_years(name).should_not be_nil
    end
  end

  describe "#purchase" do
    let(:registrant) { Registrar::Contact.new }
    let(:order) { stub("Order") }
    let(:purchase_options) { nil }

    it "requires a registrant" do
      lambda { client.purchase(name) }.should raise_error
      lambda { client.purchase(name, nil) }.should raise_error
    end
    context "with a successful registration" do
      it "returns an order upon success" do
        provider.expects(:purchase).with(name, registrant, purchase_options).returns(order)
        order = client.purchase(name, registrant)
        order.should_not be_nil
      end
    end
  end

  describe "#name_servers" do
    it "returns a list of name servers attached to the domain" do
      provider.expects(:name_servers).with(name).returns([])
      name_servers = client.name_servers(name)
    end
  end

  describe "#name_servers=" do
    let(:name_servers) { ['ns1.example.com', 'ns2.example.com'] }
    it "sets the name servers" do
      provider.expects(:set_name_servers).with(name, name_servers).returns(name_servers)
      client.set_name_servers(name, name_servers).should eq(name_servers)
    end
  end
end

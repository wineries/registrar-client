require 'spec_helper'

describe Registrar::PurchaseOptions do
  context "by default" do
    subject { Registrar::PurchaseOptions.new }
    it "does not specify name servers" do
      subject.has_name_servers?.should be_false
    end
    it "does not specify extended attributes" do
      subject.has_extended_attributes?.should be_false
    end
    it "returns 1 for number of years" do
      subject.number_of_years.should eq 1
    end
  end

  context 'setting values' do
    let(:options) { Registrar::PurchaseOptions.new }

    it 'sets the number of years' do 
      options.number_of_years= 3
      options.number_of_years.should eq 3
    end

    it "sets the name servers" do
      options.name_servers = ['ns1.example.com','ns2.example.com']
      options.has_name_servers?.should be_true
    end

    it "has a language which can be set" do
      options.language = "english"
      options.language.should eq("english")
    end
  end
end

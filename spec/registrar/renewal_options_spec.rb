require 'spec_helper'

describe Registrar::RenewalOptions do
  context "by default" do
    subject { Registrar::RenewalOptions.new }
    it "returns 1 for the number of years" do
      subject.number_of_years.should eq(1)
    end
  end

  context "setting values" do
    let(:options) { Registrar::RenewalOptions.new }
  end
end

require 'spec_helper'

describe Registrar::Domain do
  let(:name) { "example.com" }
  it "is initialized with a name" do
    domain = Registrar::Domain.new(name)
    domain.name.should eq(name)
  end
end

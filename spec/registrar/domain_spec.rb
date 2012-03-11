require 'spec_helper'

describe Registrar::Domain do
  let(:name) { "example.com" }
  let(:domain) { Registrar::Domain.new(name) }

  it "is initialized with a name" do
    domain.name.should eq(name)
  end

  it "is lockable" do
    domain.lockable = true
    domain.should be_lockable
  end

  it "is real time" do
    domain.real_time = true
    domain.should be_real_time
  end
end

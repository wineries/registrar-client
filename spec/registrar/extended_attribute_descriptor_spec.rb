require 'spec_helper'

describe Registrar::ExtendedAttributeDescriptor do
  let(:name) { 'example name' }
  let(:description) { 'This is an example extended attribute' }

  subject do
    d = Registrar::ExtendedAttributeDescriptor.new
    d.name = name
    d.description = description
    d.required = true
    d
  end

  it "has a name" do
    subject.name.should eq(name)
  end
  it "has a description" do
    subject.description.should eq(description)
  end
  it "is required" do
    subject.should be_required
  end
end


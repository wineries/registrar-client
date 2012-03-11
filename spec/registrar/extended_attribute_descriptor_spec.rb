require 'spec_helper'

describe Registrar::ExtendedAttributeDescriptor do
  let(:name) { 'example name' }
  let(:description) { 'This is an example extended attribute' }

  subject do
    d = Registrar::ExtendedAttributeDescriptor.new
    d.name = name
    d.description = description
    d.required = true
    d.application = "2"
    d.user_defined = true
    d.options << Registrar::ExtendedAttributeOptionDescriptor.new
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
  it "is not a child" do
    subject.should_not be_child
  end
  it "has an application value" do
    subject.application.should eq("2")
  end
  it "is user defined" do
    subject.should be_user_defined
  end
  it "has options" do
    subject.options.should_not be_empty
  end

  describe "#to_hash" do
    it "is a hash with a name" do
      subject.serializable_hash['name'].should eq(subject.name)
    end
  end
end


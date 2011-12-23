require 'spec_helper'

describe Registrar::ExtendedAttributeOptionDescriptor do
  let(:title) { "title" }
  let(:value) { "value" }
  let(:description) { "description" }

  subject do
    d = Registrar::ExtendedAttributeOptionDescriptor.new
    d.title = title
    d.value = value
    d.description = description
    d
  end

  it "has a title" do
    subject.title.should eq(title)
  end

  it "has a value" do
    subject.value.should eq(value)
  end

  it "has a description" do
    subject.description.should eq(description)
  end

end

require 'registrar'

shared_examples "a real-time domain without extended attributes" do
  describe "#purchase" do
    let(:order) { client.purchase(name, registrant) }
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

  describe "#renew" do
    let(:domain) do
      order = client.purchase(name, registrant)
      order.domain
    end
    let(:order) do
      client.renew(domain.name)
    end
    it "returns a completed order" do
      order.should be_complete 
    end
    it "extends the domain for 1 year" do
      domain.expires_at.should eq(2.years.from_now)
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
